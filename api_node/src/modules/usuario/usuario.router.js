// src/modules/usuario/usuario.router.js
const router = require("express").Router();
const { list, getById, update, updateByPersona, remove } = require("./usuario.controller");

router.get("/", list);
router.get("/:id", getById);
router.put("/:id", update);
router.put("/by-persona/:idpersona", updateByPersona); // 👈 para editar correo desde persona
router.delete("/:id", remove);

module.exports = router;
