// Controlador de CATEGORÍAS: HTTP ↔ service
const service = require('./categoria.service');

async function list(req, res) {
  try {
    const data = await service.list();
    res.json(data);
  } catch (err) {
    console.error('Categorias list error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function getById(req, res) {
  try {
    const { id } = req.params;
    const item = await service.getById(id);
    if (!item) return res.status(404).json({ error: 'Categoría no encontrada' });
    res.json(item);
  } catch (err) {
    console.error('Categorias getById error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function create(req, res) {
  try {
    const { nombre, descripcion } = req.body;
    if (!nombre) return res.status(400).json({ error: 'nombre es requerido' });

    const created = await service.create({ nombre, descripcion });
    res.status(201).json(created);
  } catch (err) {
    console.error('Categorias create error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function update(req, res) {
  try {
    const { id } = req.params;
    const { nombre, descripcion } = req.body;

    const updated = await service.update(id, { nombre, descripcion });
    if (!updated) return res.status(404).json({ error: 'Categoría no encontrada' });
    res.json(updated);
  } catch (err) {
    console.error('Categorias update error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function remove(req, res) {
  try {
    const { id } = req.params;
    const ok = await service.remove(id);
    if (!ok) return res.status(404).json({ error: 'Categoría no encontrada' });
    res.json({ ok: true });
  } catch (err) {
    console.error('Categorias remove error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = { list, getById, create, update, remove };
