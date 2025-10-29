// src/modules/ubicacion/ubicacion.router.js
const router = require("express").Router();
const { listByPersona, add, update, remove } = require("./ubicacion.controller");

router.get("/:idpersona", listByPersona);
router.post("/:idpersona", add);
router.put("/:idubicacion", update);
router.delete("/:idubicacion", remove);

module.exports = router;
