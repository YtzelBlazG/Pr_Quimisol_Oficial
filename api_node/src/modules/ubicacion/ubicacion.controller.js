const ubicacionService = require("./ubicacion.service");

async function listByPersona(req, res) {
  res.json(await ubicacionService.listByPersona(req.params.idpersona));
}

async function add(req, res) {
  const { nombre, latitud, longitud, direccion, ciudad } = req.body || {};
  if (!nombre || !String(nombre).trim() || !direccion || !ciudad) {
    return res.status(400).json({ error: "nombre, ciudad y direccion son requeridos" });
  }
  const nueva = await ubicacionService.add(req.params.idpersona, {
    nombre: String(nombre).trim(),
    latitud,
    longitud,
    direccion,
    ciudad,
  });
  res.status(201).json(nueva);
}

/* Si ya tienes update/remove, agrega validación de nombre: */
async function update(req, res) {
  const upd = await ubicacionService.update(req.params.idubicacion, req.body);
  if (!upd) return res.status(404).json({ error: "Ubicación no encontrada" });
  res.json(upd);
}

async function remove(req, res) {
  const ok = await ubicacionService.remove(req.params.idubicacion);
  if (!ok) return res.status(404).json({ error: "Ubicación no encontrada" });
  res.json({ message: "Ubicación eliminada" });
}

module.exports = { listByPersona, add, update, remove };
