// src/modules/ubicacion/ubicacion.controller.js
const ubicacionService = require("./ubicacion.service");

async function listByPersona(req, res, next) {
  try {
    const idpersona = Number(req.params.idpersona);
    if (!Number.isInteger(idpersona)) {
      return res.status(400).json({ error: "idpersona inválido" });
    }
    const data = await ubicacionService.listByPersona(idpersona);
    res.json(data);
  } catch (e) {
    next(e);
  }
}

async function add(req, res, next) {
  try {
    const idpersona = Number(req.params.idpersona);
    if (!Number.isInteger(idpersona)) {
      return res.status(400).json({ error: "idpersona inválido" });
    }

    const { nombre, latitud, longitud, direccion, ciudad } = req.body || {};

    if (!nombre || !String(nombre).trim() || !direccion || !ciudad) {
      return res
        .status(400)
        .json({ error: "nombre, ciudad y direccion son requeridos" });
    }

    const lat = latitud === undefined ? null : Number(latitud);
    const lng = longitud === undefined ? null : Number(longitud);

    const nueva = await ubicacionService.add(idpersona, {
      nombre: String(nombre).trim(),
      latitud: lat,
      longitud: lng,
      direccion: String(direccion).trim(),
      ciudad: String(ciudad).trim(),
    });

    res.status(201).json(nueva);
  } catch (e) {
    next(e);
  }
}

async function update(req, res, next) {
  try {
    const idubicacion = Number(req.params.idubicacion);
    if (!Number.isInteger(idubicacion)) {
      return res.status(400).json({ error: "idubicacion inválido" });
    }

    const payload = { ...req.body };
    if (payload.latitud !== undefined) payload.latitud = Number(payload.latitud);
    if (payload.longitud !== undefined) payload.longitud = Number(payload.longitud);

    const upd = await ubicacionService.update(idubicacion, payload);
    if (!upd) return res.status(404).json({ error: "Ubicación no encontrada" });
    res.json(upd);
  } catch (e) {
    next(e);
  }
}

async function remove(req, res, next) {
  try {
    const idubicacion = Number(req.params.idubicacion);
    if (!Number.isInteger(idubicacion)) {
      return res.status(400).json({ error: "idubicacion inválido" });
    }
    const ok = await ubicacionService.remove(idubicacion);
    if (!ok) return res.status(404).json({ error: "Ubicación no encontrada" });
    // 204: borrado lógico exitoso sin body
    res.status(204).end();
  } catch (e) {
    next(e);
  }
}

module.exports = { listByPersona, add, update, remove };
