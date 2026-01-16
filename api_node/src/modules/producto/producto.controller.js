// Controlador de PRODUCTOS: HTTP ↔ service
const service = require('./producto.service');

// ==========================
// 🔹 Listar todos
// ==========================
async function list(req, res) {
  try {
    const data = await service.list();
    res.json(data);
  } catch (err) {
    console.error('Productos list error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// ==========================
// 🔹 Obtener por ID
// ==========================
async function getById(req, res) {
  try {
    const { id } = req.params;
    const item = await service.getById(id);
    if (!item) return res.status(404).json({ error: 'No encontrado' });
    res.json(item);
  } catch (err) {
    console.error('Productos getById error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// ==========================
// 🔹 Crear nuevo
// ==========================
async function create(req, res) {
  try {
    const { codigo, nombre, descripcion, idunidad, idcategoria, imagen, precio } = req.body;

    if (!codigo || !nombre || !idunidad || !idcategoria) {
      return res.status(400).json({
        error: 'codigo, nombre, idunidad e idcategoria son requeridos'
      });
    }

    const created = await service.create({
      codigo,
      nombre,
      descripcion,
      idunidad,
      idcategoria,
      imagen,
      precio
    });

    res.status(201).json(created);
  } catch (err) {
    console.error('Productos create error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// ==========================
// 🔹 Actualizar existente
// ==========================
async function update(req, res) {
  try {
    const { id } = req.params;
    const { codigo, nombre, descripcion, idunidad, idcategoria, imagen, precio } = req.body;

    const updated = await service.update(id, {
      codigo,
      nombre,
      descripcion,
      idunidad,
      idcategoria,
      imagen,
      precio
    });

    if (!updated) return res.status(404).json({ error: 'No encontrado' });
    res.json(updated);
  } catch (err) {
    console.error('Productos update error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// ==========================
// 🔹 Borrado lógico
// ==========================
async function remove(req, res) {
  try {
    const { id } = req.params;
    const ok = await service.remove(id);
    if (!ok) return res.status(404).json({ error: 'No encontrado' });
    res.json({ ok: true });
  } catch (err) {
    console.error('Productos remove error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
};
