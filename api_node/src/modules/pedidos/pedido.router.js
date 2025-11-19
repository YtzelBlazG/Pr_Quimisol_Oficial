// src/modules/pedidos/pedido.router.js
const { Router } = require('express');
const {
  crearPedidoDesdeCarrito,
  listarPedidosDeUsuario,
  listarTodosLosPedidos,
  listarPedidosPorUbicacion,
  obtenerPedidoConDetalles,
  guardarUbicacionesDePedido,
  listarPedidosDeRepartidor,
  actualizarPosicionRepartidor,
  actualizarEstadoUbicacionPedido,
  marcarUbicacionEnCamino,
  obtenerPosicionRepartidorPorUbicacion, // ✅ import del controller
} = require('./pedido.controller');

const router = Router();

// Listar TODOS los pedidos (panel admin)
router.get('/', listarTodosLosPedidos);

// Listar pedidos "por ubicación" (sub-pedidos por cada entrega)
router.get('/por-ubicacion', listarPedidosPorUbicacion);

// 🔹 Listar pedidos de un repartidor (por idPersona del repartidor)
router.get('/repartidores/:idPersona/pedidos', listarPedidosDeRepartidor);

// 🔹 Actualizar posición actual de un repartidor
router.patch('/repartidores/:idPersona/posicion', actualizarPosicionRepartidor);

// 🔹 Marcar una ubicación como EN CAMINO y asignarla al repartidor
router.patch(
  '/repartidores/:idPersona/pedidos/:idPedido/ubicaciones/:idUbicacion/en-camino',
  marcarUbicacionEnCamino
);

// 🔹 Endpoint para el tracking del repartidor (cliente)
router.get(
  '/:idPedido/ubicaciones/:idUbicacion/posicion-repartidor',
  obtenerPosicionRepartidorPorUbicacion
);

// Crear pedido desde carrito
router.post('/crear-desde-carrito/:idUsuario', crearPedidoDesdeCarrito);

// Listar pedidos de un usuario (app cliente)
router.get('/usuario/:idUsuario', listarPedidosDeUsuario);

// 🔹 Actualizar estado de UNA ubicación de un pedido
router.patch(
  '/:idPedido/ubicaciones/:idUbicacion/estado',
  actualizarEstadoUbicacionPedido
);

// Obtener pedido con detalles
router.get('/:idPedido', obtenerPedidoConDetalles);

// Guardar ubicaciones asociadas a un pedido
router.put('/:idPedido/ubicaciones', guardarUbicacionesDePedido);

module.exports = router;
