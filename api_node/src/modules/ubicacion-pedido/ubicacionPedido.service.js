// src/modules/ubicacion-pedido/ubicacionPedido.service.js

// Import "tolerante" para tu db.js (igual que en pedidos)
const dbModule = require('../../config/db');
const pool =
  (dbModule && (dbModule.pool || dbModule.pgPool || dbModule.default || dbModule)) || null;

if (!pool || typeof pool.connect !== 'function') {
  console.error('[ubicacion-pedido] No se pudo obtener un Pool válido desde src/config/db.js.');
  console.error('[ubicacion-pedido] Valor recibido de require("../../config/db"):', dbModule);
  throw new Error(
    'DB Pool inválido: verifica que src/config/db.js exporte un Pool de pg (Pool.connect disponible).'
  );
}

/**
 * Crea un vínculo (usuario + pedido + ubicación) en la tabla ubicacion_pedido.
 * - idpedido puede ser null si aún no se ha creado el pedido.
 * - idusuario e idubicacion son obligatorios.
 */
async function crearUbicacionPedidoService({ idusuario, idpedido = null, idubicacion }) {
  const { rows } = await pool.query(
    `
    INSERT INTO ubicacion_pedido (idusuario, idpedido, idubicacion)
    VALUES ($1, $2, $3)
    RETURNING id, idusuario, idpedido, idubicacion, createdon, updatedon
    `,
    [idusuario, idpedido, idubicacion]
  );

  return rows[0];
}

/**
 * Lista TODAS las ubicaciones asociadas a un pedido específico.
 * Devuelve datos de la tabla ubicacion + metadata de vinculación.
 */
async function listarUbicacionesDePedidoService(idPedido) {
  const { rows } = await pool.query(
    `
    SELECT
      u.idubicacion,
      u.nombre,
      u.direccion,
      u.ciudad,
      u.latitud,
      u.longitud,
      u.createdon,
      u.updatedon,
      up.id             AS id_relacion,
      up.createdon      AS vinculada_en
    FROM ubicacion_pedido up
    JOIN ubicacion u ON u.idubicacion = up.idubicacion
    WHERE up.idpedido = $1
      AND (u.deletedon IS NULL)
    ORDER BY up.createdon ASC
    `,
    [idPedido]
  );

  return rows;
}

module.exports = {
  crearUbicacionPedidoService,
  listarUbicacionesDePedidoService,
};
