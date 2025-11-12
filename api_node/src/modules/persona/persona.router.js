// src/modules/persona/persona.router.js
const router = require("express").Router();
const { list, getById, update, remove } = require("./persona.controller");

router.get("/", list);
router.get("/:id", getById);
router.put("/:id", update);   // ✅ aquí la ruta es singular "/persona/:id"
router.delete("/:id", remove);

module.exports = router;
