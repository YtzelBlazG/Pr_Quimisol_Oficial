const express = require('express');
const router = express.Router();
const controller = require('./carrito.controller');

router.post('/', controller.create);
router.get('/:idusuario', controller.getByUsuario); // ✅ NUEVA RUTA
router.delete('/:idusuario/:idproducto', controller.eliminarDelCarrito);

module.exports = router;
