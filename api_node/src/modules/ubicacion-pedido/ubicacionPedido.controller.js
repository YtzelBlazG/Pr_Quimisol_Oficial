// src/modules/ubicacion-pedido/ubicacionPedido.controller.js

const {
  crearUbicacionPedidoService,
  listarUbicacionesDePedidoService,
} = require('./ubicacionPedido.service');

/**
 * POST /ubicacion-pedido
 * Body:
 * {
 *   "idusuario": 18,
 *   "idpedido": 13,       // puede ser null
 *   "idubicacion": 19
 * }
 */
async function crearUbicacionPedido(req, res) {
  try {
    const { idusuario, idpedido, idubicacion } = req.body;

    if (!idusuario || !idubicacion) {
      return res.status(400).json({
        message: 'idusuario e idubicacion son obligatorios.',
      });
    }

    const data = await crearUbicacionPedidoService({
      idusuario,
      idpedido: idpedido ?? null,
      idubicacion,
    });

    return res.status(201).json({
      message: 'Ubicación vinculada al pedido correctamente.',
      data,
    });
  } catch (err) {
    console.error('crearUbicacionPedido:', err);
    return res
      .status(500)
      .json({ message: 'Error al vincular ubicación al pedido.' });
  }
}

/**
 * GET /ubicacion-pedido/pedido/:idPedido
 * Devuelve todas las ubicaciones asociadas a ese pedido.
 */
async function listarUbicacionesDePedido(req, res) {
  try {
    const { idPedido } = req.params;

    const ubicaciones = await listarUbicacionesDePedidoService(idPedido);

    return res.json(ubicaciones);
  } catch (err) {
    console.error('listarUbicacionesDePedido:', err);
    return res
      .status(500)
      .json({ message: 'Error al listar ubicaciones del pedido.' });
  }
}

module.exports = {
  crearUbicacionPedido,
  listarUbicacionesDePedido,
};
