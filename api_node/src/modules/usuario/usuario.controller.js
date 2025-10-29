// src/modules/usuario/usuario.controller.js
const service = require('./usuario.service');

async function list(req, res) {
  try {
    const usuarios = await service.list(); // retorna array
    res.json(usuarios);
  } catch (e) {
    console.error('❌ Error list usuarios:', e);
    res.status(500).json({ error: 'Error al listar usuarios' });
  }
}

async function getById(req, res) {
  try {
    const usuario = await service.getById(req.params.id);
    if (!usuario) return res.status(404).json({ message: 'Usuario no encontrado' });
    res.json(usuario);
  } catch (e) {
    console.error('❌ Error get usuario:', e);
    res.status(500).json({ error: 'Error al obtener usuario' });
  }
}

async function update(req, res) {
  try {
    const updated = await service.update(req.params.id, req.body);
    if (!updated) return res.status(404).json({ message: 'Usuario no encontrado' });
    res.json(updated);
  } catch (e) {
    console.error('❌ Error update usuario:', e);
    res.status(500).json({ error: 'Error al actualizar usuario' });
  }
}

async function updateByPersona(req, res) {
  try {
    const updated = await service.updateByPersona(req.params.idpersona, req.body);
    if (!updated) return res.status(404).json({ message: 'Usuario no encontrado por persona' });
    res.json(updated);
  } catch (e) {
    console.error('❌ Error update usuario by persona:', e);
    res.status(500).json({ error: 'Error al actualizar usuario por persona' });
  }
}

async function remove(req, res) {
  try {
    const deleted = await service.remove(req.params.id);
    if (!deleted) return res.status(404).json({ message: 'Usuario no encontrado' });
    res.json({ message: 'Usuario eliminado' });
  } catch (e) {
    console.error('❌ Error remove usuario:', e);
    res.status(500).json({ error: 'Error al eliminar usuario' });
  }
}

module.exports = { list, getById, update, updateByPersona, remove };
