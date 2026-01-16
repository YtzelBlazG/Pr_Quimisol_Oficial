const service = require('./favoritos.service');

// GET /favoritos
exports.list = async (req, res) => {
  try {
    const data = await service.list();
    res.json(data);
  } catch (err) {
    console.error('Favoritos list error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// POST /favoritos
exports.create = async (req, res) => {
  try {
    const newItem = await service.create(req.body);
    res.status(201).json(newItem);
  } catch (err) {
    console.error('Favoritos create error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// GET /favoritos/:idusuario
exports.getByUsuario = async (req, res) => {
  try {
    const { idusuario } = req.params;
    const productos = await service.getByUsuario(idusuario);
    res.json(productos);
  } catch (err) {
    console.error('Favoritos getByUsuario error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// DELETE /favoritos/:idusuario/:idproducto
exports.delete = async (req, res) => {
  try {
    const { idusuario, idproducto } = req.params;
    await service.delete(idusuario, idproducto);
    res.json({ success: true });
  } catch (err) {
    console.error('Favoritos delete error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};
