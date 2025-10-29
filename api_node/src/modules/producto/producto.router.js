// Router de PRODUCTOS (mismo shape que tu proyecto)
const express = require('express');
const ctrl = require('./producto.controller');
const router = express.Router();

router.get('/', ctrl.list);
router.get('/:id', ctrl.getById);
router.post('/', ctrl.create);
router.put('/:id', ctrl.update);
router.delete('/:id', ctrl.remove);

module.exports = router;
