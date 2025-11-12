// src/modules/pedidos/pedido.service.js

// ⬇️ Import "tolerante" al tipo de export de tu db.js
// Acepta: module.exports = { pool }, module.exports = pool, exports.pool = pool, export default pool
const dbModule = require('../../config/db');
const pool =
  (dbModule && (dbModule.pool || dbModule.pgPool || dbModule.default || dbModule)) || null;

if (!pool || typeof pool.connect !== 'function') {
  // Log bien explícito para que si vuelve a fallar sepas qué está entrando
  console.error('[pedidos] No se pudo obtener un Pool válido desde src/config/db.js.');
  console.error('[pedidos] Valor recibido de require("../../config/db"):', dbModule);
  throw new Error(
    'DB Pool inválido: verifica que src/config/db.js exporte un Pool de pg (Pool.connect disponible).'
  );
}

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

    // 2) Total
    const total = items.reduce((acc, it) => {
      const precio = Number(it.precio) || 0;
      const cant = Number(it.cantidad) || 0;
      return acc + precio * cant;
    }, 0);

    // 3) Cabecera pedido
    const { rows: pedidoRows } = await client.query(
      `
      INSERT INTO pedido (idusuario, fecha, estado, total)
      VALUES ($1, CURRENT_DATE, 'pendiente', $2::numeric(12,2))
      RETURNING idpedido, idusuario, fecha, estado, total, createdon
      `,
      [idUsuario, total.toFixed(2)]
    );
    const pedido = pedidoRows[0];

    // 4) Detalles
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

    // (Opcional) Descontar stock aquí

    // 5) Limpiar carrito
    await client.query(`DELETE FROM carrito WHERE idusuario = $1`, [idUsuario]);

    await client.query('COMMIT');

    const detalles = items.map((it) => ({
      idproducto: it.idproducto,
      nombre: it.nombre,
      cantidad: it.cantidad,
      preciounitario: Number(it.precio),
      subtotal: Number(it.precio) * Number(it.cantidad),
    }));

    return { pedido, detalles, total };
  } catch (e) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw e;
  } finally {
    client.release();
  }
}

async function listarPedidosDeUsuarioService(idUsuario) {
  const { rows } = await pool.query(
    `
    SELECT idpedido, idusuario, fecha, estado, total, createdon
    FROM pedido
    WHERE idusuario = $1
    ORDER BY createdon DESC
    `,
    [idUsuario]
  );
  return rows;
}

async function obtenerPedidoConDetallesService(idPedido) {
  const { rows: cab } = await pool.query(
    `SELECT idpedido, idusuario, fecha, estado, total, createdon
     FROM pedido WHERE idpedido = $1`,
    [idPedido]
  );
  if (cab.length === 0) {
    const err = new Error('Pedido no encontrado.');
    err.status = 404;
    throw err;
  }

  const { rows: det } = await pool.query(
    `
    SELECT d.id, d.idproducto, pr.nombre, d.cantidad,
           d.preciounitario::numeric(10,2) AS preciounitario,
           (d.cantidad * d.preciounitario)::numeric(12,2) AS subtotal
    FROM detallepedido d
    JOIN productos pr ON pr.idproducto = d.idproducto
    WHERE d.idpedido = $1
    ORDER BY d.id ASC
    `,
    [idPedido]
  );

  return { pedido: cab[0], detalles: det };
}

module.exports = {
  crearPedidoDesdeCarritoService,
  listarPedidosDeUsuarioService,
  obtenerPedidoConDetallesService,
};
