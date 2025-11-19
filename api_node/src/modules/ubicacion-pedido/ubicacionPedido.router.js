// src/modules/ubicacion-pedido/ubicacionPedido.router.js

const { Router } = require('express');
const {
  crearUbicacionPedido,
  listarUbicacionesDePedido,
} = require('./ubicacionPedido.controller');

const router = Router();

// POST /ubicacion-pedido
// Crea una relación usuario + pedido + ubicación
router.post('/', crearUbicacionPedido);

// GET /ubicacion-pedido/pedido/:idPedido
// Lista todas las ubicaciones vinculadas a ese pedido
router.get('/pedido/:idPedido', listarUbicacionesDePedido);

module.exports = router;
