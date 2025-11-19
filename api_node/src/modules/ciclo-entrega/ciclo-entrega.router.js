// src/modules/ciclo-entrega/ciclo-entrega.router.js

const express = require('express');
const router = express.Router();

const {
  listarPorAnio,
  generarParaAnio,
  obtenerPorId,
  actualizarCiclo,

  listarRepartidoresActivos,
  obtenerRepartidoresDeCiclo,
  guardarRepartidoresDeCiclo,
} = require('./ciclo-entrega.controller');

// Lista ciclos de un año:
// - /ciclos-entrega?anio=2025   (lo usa Flutter)
// - /ciclos-entrega/anio/2025  (opcional)
router.get('/', listarPorAnio);
router.get('/anio/:anio', listarPorAnio);

// ⚠️ RUTA ESPECÍFICA ANTES DE /:idciclo...
// Lista todos los repartidores activos
router.get('/repartidores', listarRepartidoresActivos);

// Generar/forzar ciclos para un año con un día concreto
router.post('/anio/:anio/generar', generarParaAnio);

// Obtener ciclo por id
router.get('/:idciclo', obtenerPorId);

// Actualizar ciclo (cambiar día o estado)
router.put('/:idciclo', actualizarCiclo);

// Repartidores asignados a un ciclo
router.get('/:idciclo/repartidores', obtenerRepartidoresDeCiclo);
router.put('/:idciclo/repartidores', guardarRepartidoresDeCiclo);

module.exports = router;
