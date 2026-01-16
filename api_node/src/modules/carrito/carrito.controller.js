const service = require('./carrito.service');

exports.create = async (req, res) => {
  try {
    const result = await service.create(req.body);
    res.status(201).json(result);
  } catch (err) {
    if (err.status === 409) {
      res.status(409).json({ error: 'Stock insuficiente' });
    } else {
      console.error('Error carrito:', err);
      res.status(500).json({ error: 'Error interno' });
    }
  }
};

exports.getByUsuario = async (req, res) => {
  try {
    const { idusuario } = req.params;
    const productos = await service.getByUsuario(idusuario);
    res.json(productos);
  } catch (err) {
    console.error('Error al obtener carrito:', err);
    res.status(500).json({ error: 'Error al obtener el carrito' });
  }
};



exports.eliminarDelCarrito = async (req, res) => {
  try {
    const { idusuario, idproducto } = req.params;
    const result = await service.eliminarDelCarrito(idusuario, idproducto);
    
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Producto no encontrado en el carrito' });
    }

    res.json({ message: 'Producto eliminado del carrito' });
  } catch (err) {
    console.error('Error al eliminar producto del carrito:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};
