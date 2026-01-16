const service = require('./detalleproducto.service');

// Listar todos los detalles
exports.list = async (req, res) => {
  try {
    const data = await service.list();
    res.json(data);
  } catch (err) {
    console.error('❌ DetalleProducto list error:', err.message);
    res.status(500).json({ error: 'Error al listar los detalles' });
  }
};

// Obtener detalle por ID
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;
    const item = await service.getById(id);
    if (!item)
      return res.status(404).json({ error: 'Detalle de producto no encontrado' });
    res.json(item);
  } catch (err) {
    console.error('❌ DetalleProducto getById error:', err.message);
    res.status(500).json({ error: 'Error al obtener el detalle' });
  }
};

// Crear nuevo detalle
exports.create = async (req, res) => {
  try {
    const { idproducto, atributo, valor, cantidad } = req.body;

    if (!idproducto || !atributo || !valor) {
      return res
        .status(400)
        .json({ error: 'Los campos idproducto, atributo y valor son obligatorios' });
    }

    const newItem = await service.create({ idproducto, atributo, valor, cantidad });
    res.status(201).json(newItem);
  } catch (err) {
    console.error('❌ DetalleProducto create error:', err.message);
    res.status(500).json({ error: 'Error al crear el detalle del producto' });
  }
};

// Actualizar detalle
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { atributo, valor, cantidad } = req.body;

    const updatedItem = await service.update(id, { atributo, valor, cantidad });
    if (!updatedItem)
      return res.status(404).json({ error: 'Detalle no encontrado para actualizar' });

    res.json(updatedItem);
  } catch (err) {
    console.error('❌ DetalleProducto update error:', err.message);
    res.status(500).json({ error: 'Error al actualizar el detalle del producto' });
  }
};

// Eliminar (borrado lógico)
exports.remove = async (req, res) => {
  try {
    const { id } = req.params;
    await service.remove(id);
    res.json({ message: '✅ Detalle eliminado correctamente' });
  } catch (err) {
    console.error('❌ DetalleProducto delete error:', err.message);
    res.status(500).json({ error: 'Error al eliminar el detalle del producto' });
  }
};
