// src/modules/pedidos/pedido.router.js
const { Router } = require('express');
const {
  crearPedidoDesdeCarrito,
  listarPedidosDeUsuario,
  obtenerPedidoConDetalles,
} = require('./pedido.controller');

const router = Router();

router.post('/crear-desde-carrito/:idUsuario', crearPedidoDesdeCarrito);
router.get('/usuario/:idUsuario', listarPedidosDeUsuario);
router.get('/:idPedido', obtenerPedidoConDetalles);

module.exports = router;
