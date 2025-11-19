// src/modules/pedidos/pedido.service.js

// ⬇️ Import "tolerante" al tipo de export de tu db.js
const dbModule = require('../../config/db');
const pool =
  (dbModule && (dbModule.pool || dbModule.pgPool || dbModule.default || dbModule)) || null;

if (!pool || typeof pool.connect !== 'function') {
  console.error('[pedidos] No se pudo obtener un Pool válido desde src/config/db.js.');
  console.error('[pedidos] Valor recibido de require("../../config/db"):', dbModule);
  throw new Error(
    'DB Pool inválido: verifica que src/config/db.js exporte un Pool de pg (Pool.connect disponible).'
  );
}

// ======================================================
// Generador de código público de pedido (QMS-XXXXXX)
// ======================================================
function generarCodigoPedido() {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // sin confusos 0/O, 1/I
  let out = '';
  for (let i = 0; i < 6; i++) {
    out += chars[Math.floor(Math.random() * chars.length)];
  }
  return `QMS-${out}`;
}

// Construye el código público (para compatibilidad con pedidos viejos)
function buildCodigoPublico(row) {
  if (!row) return null;

  if (row.codigo && String(row.codigo).trim() !== '') {
    return row.codigo;
  }

  const id = row.idpedido || row.id_pedido;
  if (!id) return null;

  // fallback determinístico si algún pedido viejo no tiene "codigo"
  return `QMS-${String(id).padStart(6, '0')}`;
}

/**
 * Crea un pedido a partir del carrito de un usuario
 * - total_base: suma de productos del carrito
 * - total_final: inicialmente igual a total_base (luego se ajusta según ubicaciones)
 * - idciclo_entrega: se asigna según ciclo_entrega.fecha_corte
 */
async function crearPedidoDesdeCarritoService(idUsuario) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1) Carrito + precio producto
    const { rows: items } = await client.query(
      `
      SELECT c.idproducto, c.cantidad, p.precio::numeric(10,2) AS precio, p.nombre
      FROM carrito c
      JOIN productos p ON p.idproducto = c.idproducto
      WHERE c.idusuario = $1
      ORDER BY c.createdon ASC
      `,
      [idUsuario]
    );

    if (items.length === 0) {
      await client.query('ROLLBACK');
      const err = new Error('Tu carrito está vacío.');
      err.status = 400;
      throw err;
    }

    // 2) Total base del pedido (solo productos)
    const totalBase = items.reduce((acc, it) => {
      const precio = Number(it.precio) || 0;
      const cant = Number(it.cantidad) || 0;
      return acc + precio * cant;
    }, 0);

    // 3) Generar código público del pedido
    const codigo = generarCodigoPedido();

    // 4) Buscar ciclo de entrega según fecha_corte en BD
    let idCicloEntrega = null;

    const { rows: cicloRows } = await client.query(
      `
      SELECT idciclo
      FROM ciclo_entrega
      WHERE estado = 'activo'
        AND fecha_corte IS NOT NULL
        AND CURRENT_DATE <= fecha_corte
      ORDER BY fecha_entrega ASC
      LIMIT 1
      `
    );

    if (cicloRows.length > 0) {
      idCicloEntrega = cicloRows[0].idciclo;
    } else {
      idCicloEntrega = null;
    }

    // 5) Cabecera pedido (incluyendo idciclo_entrega)
    const { rows: pedidoRows } = await client.query(
      `
      INSERT INTO pedido (
        idusuario,
        fecha,
        estado,
        total,
        total_base,
        total_final,
        codigo,
        idciclo_entrega
      )
      VALUES (
        $1,
        CURRENT_DATE,
        'pedido',
        $2::numeric(12,2),
        $2::numeric(12,2),
        $2::numeric(12,2),
        $3,
        $4
      )
      RETURNING
        idpedido,
        idusuario,
        fecha,
        estado,
        total,
        total_base,
        total_final,
        codigo,
        idciclo_entrega,
        createdon
      `,
      [idUsuario, totalBase.toFixed(2), codigo, idCicloEntrega]
    );

    const pedidoRow = pedidoRows[0];
    const pedido = {
      ...pedidoRow,
      codigo_publico: buildCodigoPublico(pedidoRow),
    };

    // 6) Detalles
    const insertDetalle = `
      INSERT INTO detallepedido (idpedido, idproducto, cantidad, preciounitario, tipoventa)
      VALUES ($1, $2, $3, $4::numeric(10,2), 'unidad')
    `;
    for (const it of items) {
      await client.query(insertDetalle, [
        pedido.idpedido,
        it.idproducto,
        it.cantidad,
        Number(it.precio).toFixed(2),
      ]);
    }

    // 7) Limpiar carrito
    await client.query(`DELETE FROM carrito WHERE idusuario = $1`, [idUsuario]);

    await client.query('COMMIT');

    const detalles = items.map((it) => ({
      idproducto: it.idproducto,
      nombre: it.nombre,
      cantidad: it.cantidad,
      preciounitario: Number(it.precio),
      subtotal: Number(it.precio) * Number(it.cantidad),
    }));

    // total devuelto = total_base (igual a total_final inicial)
    return { pedido, detalles, total: totalBase };
  } catch (e) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {}
    throw e;
  } finally {
    client.release();
  }
}

/**
 * Lista pedidos de un usuario (app cliente)
 */
async function listarPedidosDeUsuarioService(idUsuario) {
  const { rows } = await pool.query(
    `
    SELECT
      p.idpedido,
      p.idusuario,
      p.fecha,
      p.estado,
      p.total,
      p.total_base,
      p.total_final,
      p.codigo,
      p.idciclo_entrega,
      CASE
        WHEN p.codigo IS NULL OR p.codigo = '' THEN
          'QMS-' || LPAD(p.idpedido::text, 6, '0')
        ELSE p.codigo
      END AS codigo_publico,
      p.createdon,
      c.fecha_entrega AS fecha_ciclo_entrega
    FROM pedido p
    LEFT JOIN ciclo_entrega c
      ON c.idciclo = p.idciclo_entrega
    WHERE p.idusuario = $1
    ORDER BY p.createdon DESC
    `,
    [idUsuario]
  );
  return rows;
}

/**
 * Lista TODOS los pedidos (panel admin)
 */
async function listarTodosLosPedidosService() {
  const { rows } = await pool.query(
    `
    SELECT
      p.idpedido,
      p.idusuario,
      p.fecha,              -- fecha del pedido
      p.estado,
      p.total,
      p.total_base,
      p.total_final,
      p.codigo,
      p.idciclo_entrega,
      CASE
        WHEN p.codigo IS NULL OR p.codigo = '' THEN
          'QMS-' || LPAD(p.idpedido::text, 6, '0')
        ELSE p.codigo
      END AS codigo_publico,
      p.createdon,

      -- Nombre del cliente (se obtiene via usuario → persona)
      per_cli.nombre AS cliente_nombre,

      -- Fecha del ciclo de entrega asignado
      c.fecha_entrega AS fecha_ciclo_entrega
    FROM pedido p
    LEFT JOIN ciclo_entrega c
      ON c.idciclo = p.idciclo_entrega
    LEFT JOIN usuario u_cli
      ON u_cli.idusuario = p.idusuario
    LEFT JOIN persona per_cli
      ON per_cli.idpersona = u_cli.idpersona
    ORDER BY p.createdon DESC
    `
  );
  return rows;
}

/**
 * Lista pedidos "por ubicación" (una fila por cada (pedido, ubicación)).
 * Útil para panel admin / reportes.
 */
async function listarPedidosPorUbicacionService() {
  const { rows } = await pool.query(
    `
    SELECT
      p.idpedido,
      p.idusuario,
      p.fecha,
      p.estado,
      p.total,
      p.total_base,
      p.total_final,
      p.codigo,
      CASE
        WHEN p.codigo IS NULL OR p.codigo = '' THEN
          'QMS-' || LPAD(p.idpedido::text, 6, '0')
        ELSE p.codigo
      END AS codigo_publico,
      p.idciclo_entrega,
      p.createdon,

      up.idubicacion,
      up.createdon AS relacion_createdon,

      u.nombre    AS ubicacion_nombre,
      u.direccion AS ubicacion_direccion,
      u.ciudad    AS ubicacion_ciudad,
      u.latitud   AS ubicacion_latitud,
      u.longitud  AS ubicacion_longitud
    FROM pedido p
    JOIN ubicacion_pedido up ON up.idpedido = p.idpedido
    JOIN ubicacion u ON u.idubicacion = up.idubicacion
    ORDER BY up.createdon DESC, p.createdon DESC
    `
  );
  return rows;
}

/**
 * Obtiene cabecera + detalles + ubicaciones de un pedido
 */
async function obtenerPedidoConDetallesService(idPedido) {
  // 1) Cabecera
  const { rows: cab } = await pool.query(
    `
    SELECT
      idpedido,
      idusuario,
      fecha,
      estado,
      total,
      total_base,
      total_final,
      codigo,
      idciclo_entrega,
      CASE
        WHEN codigo IS NULL OR codigo = '' THEN
          'QMS-' || LPAD(idpedido::text, 6, '0')
        ELSE codigo
      END AS codigo_publico,
      createdon
    FROM pedido
    WHERE idpedido = $1
    `,
    [idPedido]
  );

  if (cab.length === 0) {
    const err = new Error('Pedido no encontrado.');
    err.status = 404;
    throw err;
  }

  // 2) Detalles
  const { rows: det } = await pool.query(
    `
    SELECT
      d.id,
      d.idproducto,
      pr.nombre,
      d.cantidad,
      d.preciounitario::numeric(10,2) AS preciounitario,
      (d.cantidad * d.preciounitario)::numeric(12,2) AS subtotal
    FROM detallepedido d
    JOIN productos pr ON pr.idproducto = d.idproducto
    WHERE d.idpedido = $1
    ORDER BY d.id ASC
    `,
    [idPedido]
  );

  // 3) Ubicaciones asociadas al pedido
  const { rows: ubis } = await pool.query(
    `
    SELECT
      u.idubicacion,
      u.nombre,
      u.direccion,
      u.ciudad,
      u.latitud,
      u.longitud
    FROM ubicacion_pedido up
    JOIN ubicacion u ON u.idubicacion = up.idubicacion
    WHERE up.idpedido = $1
    ORDER BY up.createdon ASC, u.idubicacion ASC
    `,
    [idPedido]
  );

  return {
    pedido: cab[0],
    detalles: det,
    ubicaciones: ubis,
  };
}

/**
 * Guarda las ubicaciones seleccionadas para un pedido.
 * - Borra las relaciones anteriores
 * - Inserta las nuevas
 * - Recalcula total_final = total_base * cantidad_ubicaciones
 *   y actualiza también total (para reportes/admin).
 */
async function guardarUbicacionesDePedidoService(idPedido, ubicacionesIds) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1) Verificar que el pedido exista y obtener idusuario + total_base/total
    const { rows: pedidoRows } = await client.query(
      `
      SELECT
        idusuario,
        total_base,
        total
      FROM pedido
      WHERE idpedido = $1
      `,
      [idPedido]
    );

    if (pedidoRows.length === 0) {
      const err = new Error('Pedido no encontrado.');
      err.status = 404;
      throw err;
    }

    const idUsuario = pedidoRows[0].idusuario;
    const totalBaseRaw = pedidoRows[0].total_base;
    const totalRaw = pedidoRows[0].total;

    // Si total_base es null (pedidos antiguos), usamos total como base.
    const totalBase = totalBaseRaw != null ? Number(totalBaseRaw) : Number(totalRaw) || 0;

    // Filtramos y normalizamos IDs de ubicaciones
    const uniqueUbicaciones = Array.from(
      new Set(
        (ubicacionesIds || [])
          .map((x) => Number(x))
          .filter((n) => Number.isFinite(n))
      )
    );

    // 2) Borrar relaciones anteriores de ese pedido
    await client.query('DELETE FROM ubicacion_pedido WHERE idpedido = $1', [idPedido]);

    // 3) Insertar nuevas relaciones
    const insertSql = `
      INSERT INTO ubicacion_pedido (idusuario, idpedido, idubicacion)
      VALUES ($1, $2, $3)
      ON CONFLICT (idpedido, idubicacion) DO NOTHING
    `;

    for (const idUb of uniqueUbicaciones) {
      await client.query(insertSql, [idUsuario, idPedido, idUb]);
    }

    // 4) Recalcular total_final en función de la cantidad de ubicaciones
    const cantUbicaciones = uniqueUbicaciones.length || 1; // por seguridad nunca 0
    const totalFinal = totalBase * cantUbicaciones;

    await client.query(
      `
      UPDATE pedido
      SET
        total_final = $2::numeric(12,2),
        total       = $2::numeric(12,2),
        updatedon   = NOW()
      WHERE idpedido = $1
      `,
      [idPedido, totalFinal.toFixed(2)]
    );

    await client.query('COMMIT');
  } catch (e) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {}
    throw e;
  } finally {
    client.release();
  }
}

/**
 * 🔹 Lista pedidos para un REPARTIDOR específico (por idPersona del repartidor)
 * Solo pedidos de ciclos donde el repartidor está asignado (ciclo_repartidor),
 * e incluye UNA ubicación principal (la primera asociada al pedido).
 */
async function listarPedidosDeRepartidorService(idPersonaRepartidor) {
  const { rows } = await pool.query(
    `
    SELECT
      p.idpedido,
      p.idusuario          AS idusuario_cliente,
      p.fecha,
      p.estado,
      p.total,
      p.total_base,
      p.total_final,
      p.codigo,
      p.idciclo_entrega,
      p.createdon,
      c.anio,
      c.mes,
      c.fecha_entrega      AS fecha_ciclo_entrega,

      per_cli.nombre       AS cliente_nombre,

      -- Ubicación principal del pedido (primera)
      ub.idubicacion       AS ubicacion_id,
      ub.nombre            AS ubicacion_nombre,
      ub.direccion         AS ubicacion_direccion,
      ub.ciudad            AS ubicacion_ciudad,
      ub.latitud           AS ubicacion_latitud,
      ub.longitud          AS ubicacion_longitud

    FROM ciclo_repartidor cr
    JOIN usuario u_rep
      ON u_rep.idusuario = cr.idusuario
    JOIN ciclo_entrega c
      ON c.idciclo = cr.idciclo
    JOIN pedido p
      ON p.idciclo_entrega = c.idciclo
    JOIN usuario u_cli
      ON u_cli.idusuario = p.idusuario
    JOIN persona per_cli
      ON per_cli.idpersona = u_cli.idpersona

    -- LATERAL: primera ubicación del pedido
    LEFT JOIN LATERAL (
      SELECT
        u.idubicacion,
        u.nombre,
        u.direccion,
        u.ciudad,
        u.latitud,
        u.longitud
      FROM ubicacion_pedido up
      JOIN ubicacion u ON u.idubicacion = up.idubicacion
      WHERE up.idpedido = p.idpedido
      ORDER BY up.createdon ASC, u.idubicacion ASC
      LIMIT 1
    ) ub ON true

    WHERE u_rep.idpersona = $1
    ORDER BY c.anio DESC, c.mes DESC, p.createdon DESC
    `,
    [idPersonaRepartidor]
  );

  return rows.map((r) => ({
    ...r,
    codigo_publico: buildCodigoPublico(r),
    nombre_cliente: r.cliente_nombre ?? '',
  }));
}

/**
 * 🔹 Actualiza la posición actual de un REPARTIDOR (por idPersona)
 * Guarda latitud / longitud en la tabla repartidor_posicion.
 */
async function actualizarPosicionRepartidorService(idPersonaRepartidor, latitud, longitud) {
  const lat = Number(latitud);
  const lng = Number(longitud);

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    const err = new Error('Latitud/longitud inválidas.');
    err.status = 400;
    throw err;
  }

  await pool.query(
    `
    INSERT INTO repartidor_posicion (idpersona, latitud, longitud, updatedon)
    VALUES ($1, $2, $3, NOW())
    ON CONFLICT (idpersona)
    DO UPDATE SET
      latitud   = EXCLUDED.latitud,
      longitud  = EXCLUDED.longitud,
      updatedon = NOW()
    `,
    [idPersonaRepartidor, lat, lng]
  );
}

module.exports = {
  crearPedidoDesdeCarritoService,
  listarPedidosDeUsuarioService,
  listarTodosLosPedidosService,
  listarPedidosPorUbicacionService,
  obtenerPedidoConDetallesService,
  guardarUbicacionesDePedidoService,
  listarPedidosDeRepartidorService,
  actualizarPosicionRepartidorService, // 👈 NUEVO
};
