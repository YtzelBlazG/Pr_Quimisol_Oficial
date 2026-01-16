// src/modules/ubicacion/ubicacion.router.js
const router = require("express").Router();
const { listByPersona, add, update, remove } = require("./ubicacion.controller");

// ⚠️ RUTA EN PLURAL: /ubicaciones
router.get("/:idpersona", listByPersona);   // GET  /ubicaciones/:idpersona
router.post("/:idpersona", add);            // POST /ubicaciones/:idpersona
router.put("/:idubicacion", update);        // PUT  /ubicaciones/:idubicacion
router.delete("/:idubicacion", remove);     // DELETE /ubicaciones/:idubicacion

module.exports = router;
