const pool = require('../../config/db');

// ==========================
// 🔹 Listar productos activos con stock real (sumado desde detallesproducto)
// ==========================
async function list() {
  const { rows } = await pool.query(`
    SELECT 
      p.idproducto,
      p.codigo,
      p.nombre,
      p.descripcion,
      p.idunidad,
      p.imagen,
      p.precio,
      COALESCE(SUM(dp.cantidad), 0) AS stock_disponible,
      p.createdon,
      p.updatedon,
      p.deletedon
    FROM productos p
    LEFT JOIN detallesproducto dp ON dp.idproducto = p.idproducto
    WHERE p.deletedon IS NULL
    GROUP BY 
      p.idproducto, p.codigo, p.nombre, p.descripcion, 
      p.idunidad, p.imagen, p.precio, p.createdon, p.updatedon, p.deletedon
    ORDER BY p.idproducto ASC
  `);

  return rows.map(r => ({
    ...r,
    precio: Number(r.precio),
    stock_disponible: Number(r.stock_disponible),
  }));
}

// ==========================
// 🔹 Obtener producto por ID (con stock real)
// ==========================
async function getById(id) {
  const { rows } = await pool.query(`
    SELECT 
      p.idproducto,
      p.codigo,
      p.nombre,
      p.descripcion,
      p.idunidad,
      p.imagen,
      p.precio,
      COALESCE(SUM(dp.cantidad), 0) AS stock_disponible,
      p.createdon,
      p.updatedon,
      p.deletedon
    FROM productos p
    LEFT JOIN detallesproducto dp ON dp.idproducto = p.idproducto
    WHERE p.idproducto = $1 AND p.deletedon IS NULL
    GROUP BY 
      p.idproducto, p.codigo, p.nombre, p.descripcion, 
      p.idunidad, p.imagen, p.precio, p.createdon, p.updatedon, p.deletedon
    LIMIT 1
  `, [id]);

  const producto = rows[0] || null;
  if (!producto) return null;

  return {
    ...producto,
    precio: Number(producto.precio),
    stock_disponible: Number(producto.stock_disponible),
  };
}

// ==========================
// 🔹 Crear producto
// ==========================
async function create({ codigo, nombre, descripcion, idunidad, imagen, precio }) {
  const { rows } = await pool.query(
    `INSERT INTO productos (codigo, nombre, descripcion, idunidad, imagen, precio, createdon)
     VALUES ($1, $2, $3, $4, $5, $6, NOW())
     RETURNING *`,
    [codigo, nombre, descripcion, idunidad, imagen, precio]
  );
  return rows[0];
}

// ==========================
// 🔹 Actualizar producto
// ==========================
async function update(id, { codigo, nombre, descripcion, idunidad, imagen, precio }) {
  const { rows } = await pool.query(
    `UPDATE productos
     SET codigo = $1, nombre = $2, descripcion = $3, idunidad = $4, imagen = $5, precio = $6, updatedon = NOW()
     WHERE idproducto = $7
     RETURNING *`,
    [codigo, nombre, descripcion, idunidad, imagen, precio, id]
  );
  return rows[0] || null;
}

// ==========================
// 🔹 Borrado lógico
// ==========================
async function remove(id) {
  const { rowCount } = await pool.query(
    'UPDATE productos SET deletedon = NOW() WHERE idproducto = $1',
    [id]
  );
  return rowCount > 0;
}

module.exports = { list, getById, create, update, remove };
