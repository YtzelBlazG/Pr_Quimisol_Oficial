// src/modules/ciclo-entrega/ciclo-entrega.service.js

const dbModule = require('../../config/db');
const pool =
  (dbModule && (dbModule.pool || dbModule.pgPool || dbModule.default || dbModule)) ||
  null;

if (!pool || typeof pool.connect !== 'function') {
  console.error('[ciclo-entrega] No se pudo obtener un Pool válido desde src/config/db.js.');
  console.error('[ciclo-entrega] Valor recibido de require("../../config/db"):', dbModule);
  throw new Error(
    'DB Pool inválido: verifica que src/config/db.js exporte un Pool de pg (Pool.connect disponible).'
  );
}

function mapCicloRow(row) {
  return {
    idciclo: row.idciclo,
    anio: row.anio,
    mes: row.mes,
    fecha_entrega: row.fecha_entrega,
    estado: row.estado,
  };
}

/**
 * Lista todos los ciclos de un año.
 * Si faltan meses, los crea con día 15 por defecto y los devuelve también.
 * Esto hace que el GET /ciclos-entrega?anio=XXXX siempre devuelva 12 meses.
 */
async function listarCiclosPorAnioService(anio) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: existentes } = await client.query(
      `
      SELECT idciclo, anio, mes, fecha_entrega, estado
      FROM ciclo_entrega
      WHERE anio = $1
      ORDER BY mes ASC;
      `,
      [anio]
    );

    const map = new Map();
    for (const r of existentes) {
      map.set(r.mes, r);
    }

    // crear los meses que falten con día 15
    for (let mes = 1; mes <= 12; mes++) {
      if (map.has(mes)) continue;

      const fechaEntrega = `${anio}-${String(mes).padStart(2, '0')}-15`;

      const { rows } = await client.query(
        `
        INSERT INTO ciclo_entrega (anio, mes, fecha_entrega, estado)
        VALUES ($1, $2, $3::date, 'activo')
        ON CONFLICT (anio, mes)
        DO UPDATE SET
          fecha_entrega = EXCLUDED.fecha_entrega,
          estado        = 'activo'
        RETURNING idciclo, anio, mes, fecha_entrega, estado;
        `,
        [anio, mes, fechaEntrega]
      );

      map.set(mes, rows[0]);
    }

    await client.query('COMMIT');

    const out = [];
    for (let mes = 1; mes <= 12; mes++) {
      out.push(mapCicloRow(map.get(mes)));
    }
    return out;
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
 * Genera (o actualiza) los 12 ciclos para un año con un día concreto.
 * NO es necesario para que el front funcione, pero lo reutilizamos desde el controller
 * si quieres un “regenerar” manual.
 *
 * defaultDia: día del mes (1..28 aprox) para fecha_entrega; por defecto 15.
 */
async function generarCiclosParaAnioService(anio, defaultDia = 15) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const resultados = [];

    for (let mes = 1; mes <= 12; mes++) {
      const dia = defaultDia;
      const fechaEntrega = `${anio}-${String(mes).padStart(2, '0')}-${String(dia).padStart(
        2,
        '0'
      )}`;

      const { rows } = await client.query(
        `
        INSERT INTO ciclo_entrega (anio, mes, fecha_entrega, estado)
        VALUES ($1, $2, $3::date, 'activo')
        ON CONFLICT (anio, mes)
        DO UPDATE SET
          fecha_entrega = EXCLUDED.fecha_entrega,
          estado        = 'activo'
        RETURNING idciclo, anio, mes, fecha_entrega, estado;
        `,
        [anio, mes, fechaEntrega]
      );

      resultados.push(mapCicloRow(rows[0]));
    }

    await client.query('COMMIT');
    return resultados;
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
 * Actualiza un ciclo de entrega.
 * - Permite cambiar fecha_entrega y/o estado.
 */
async function actualizarCicloEntregaService(idciclo, { fecha_entrega, estado }) {
  const campos = [];
  const valores = [];
  let idx = 1;

  if (fecha_entrega) {
    campos.push(`fecha_entrega = $${idx++}::date`);
    valores.push(fecha_entrega);
  }
  if (estado) {
    campos.push(`estado = $${idx++}`);
    valores.push(estado);
  }

  if (campos.length === 0) {
    const err = new Error('No se enviaron campos para actualizar.');
    err.status = 400;
    throw err;
  }

  valores.push(idciclo);

  const { rows } = await pool.query(
    `
    UPDATE ciclo_entrega
    SET ${campos.join(', ')}
    WHERE idciclo = $${idx}
    RETURNING idciclo, anio, mes, fecha_entrega, estado;
    `,
    valores
  );

  if (rows.length === 0) {
    const err = new Error('Ciclo no encontrado.');
    err.status = 404;
    throw err;
  }

  return mapCicloRow(rows[0]);
}

/**
 * Obtiene un ciclo por ID.
 */
async function obtenerCicloPorIdService(idciclo) {
  const { rows } = await pool.query(
    `
    SELECT idciclo, anio, mes, fecha_entrega, estado
    FROM ciclo_entrega
    WHERE idciclo = $1;
    `,
    [idciclo]
  );
  if (rows.length === 0) {
    const err = new Error('Ciclo no encontrado.');
    err.status = 404;
    throw err;
  }
  return mapCicloRow(rows[0]);
}

/* ============================================================
 * REPARTIDORES POR CICLO
 * ============================================================
 */

/**
 * Lista todos los repartidores activos (usuarios con rol "repartidor").
 */
async function listarRepartidoresActivosService() {
  const { rows } = await pool.query(`
    SELECT
      u.idusuario,
      per.nombre,
      u.correo
    FROM usuario u
    JOIN persona per ON per.idpersona = u.idpersona
    WHERE LOWER(u.rol) = 'repartidor'
      AND u.estado = 'activo'
    ORDER BY per.nombre ASC;
  `);
  return rows;
}


/**
 * Devuelve un arreglo con los idusuario asignados a un ciclo.
 */
async function obtenerRepartidoresDeCicloService(idciclo) {
  const { rows } = await pool.query(
    `SELECT idusuario FROM ciclo_repartidor WHERE idciclo = $1`,
    [idciclo]
  );
  return rows.map((r) => r.idusuario);
}

/**
 * Guarda la asignación de repartidores a un ciclo.
 * - Borra las asignaciones previas del ciclo.
 * - Inserta las nuevas (evitando duplicados).
 */
async function guardarRepartidoresDeCicloService(idciclo, repartidoresIds) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Borrar asignaciones existentes
    await client.query(
      `DELETE FROM ciclo_repartidor WHERE idciclo = $1`,
      [idciclo]
    );

    const unique = Array.from(
      new Set(
        (repartidoresIds || [])
          .map((x) => Number(x))
          .filter((n) => Number.isFinite(n))
      )
    );

    if (unique.length > 0) {
      const insertSql = `
        INSERT INTO ciclo_repartidor (idciclo, idusuario)
        VALUES ($1, $2)
        ON CONFLICT (idciclo, idusuario) DO NOTHING
      `;

      for (const idUsuario of unique) {
        await client.query(insertSql, [idciclo, idUsuario]);
      }
    }

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

module.exports = {
  listarCiclosPorAnioService,
  generarCiclosParaAnioService,
  actualizarCicloEntregaService,
  obtenerCicloPorIdService,

  // repartidores
  listarRepartidoresActivosService,
  obtenerRepartidoresDeCicloService,
  guardarRepartidoresDeCicloService,
};
