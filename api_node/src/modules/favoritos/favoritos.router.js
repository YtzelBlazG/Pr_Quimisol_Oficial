const express = require('express');
const controller = require('./favoritos.controller');
const router = express.Router();

// ✅ Todas las rutas alineadas con el frontend
router.get('/', controller.list); // Obtener todos los favoritos
router.post('/', controller.create); // Agregar favorito
router.get('/:idusuario', controller.getByUsuario); // Obtener por usuario
router.delete('/:idusuario/:idproducto', controller.delete); // ✅ corregido orden correcto

module.exports = router;
