// src/modules/pedidos/pedido.controller.js
const {
  crearPedidoDesdeCarritoService,
  listarPedidosDeUsuarioService,
  obtenerPedidoConDetallesService,
} = require('./pedido.service');

async function crearPedidoDesdeCarrito(req, res) {
  try {
    const { idUsuario } = req.params;
    const { pedido, detalles, total } = await crearPedidoDesdeCarritoService(idUsuario);
    return res.status(201).json({
      message: 'Pedido creado correctamente.',
      pedido,
      detalles,
      total,
    });
  } catch (err) {
    const status = err.status || 500;
    console.error('crearPedidoDesdeCarrito:', err);
    return res.status(status).json({ message: err.message || 'Error al crear el pedido.' });
  }
}

async function listarPedidosDeUsuario(req, res) {
  try {
    const { idUsuario } = req.params;
    const pedidos = await listarPedidosDeUsuarioService(idUsuario);
    return res.json(pedidos);
  } catch (err) {
    console.error('listarPedidosDeUsuario:', err);
    return res.status(500).json({ message: 'Error al listar pedidos.' });
  }
}

async function obtenerPedidoConDetalles(req, res) {
  try {
    const { idPedido } = req.params;
    const data = await obtenerPedidoConDetallesService(idPedido);
    return res.json(data);
  } catch (err) {
    const status = err.status || 500;
    console.error('obtenerPedidoConDetalles:', err);
    return res.status(status).json({ message: err.message || 'Error al obtener el pedido.' });
  }
}

module.exports = {
  crearPedidoDesdeCarrito,
  listarPedidosDeUsuario,
  obtenerPedidoConDetalles,
};
