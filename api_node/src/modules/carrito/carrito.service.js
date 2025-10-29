const pool = require('../../config/db'); // ✅ conexión a PostgreSQL

// ➕ Agregar producto al carrito
exports.create = async ({ idusuario, idproducto, cantidad }) => {
  // 1. Verificar si ya existe el producto en el carrito
  const carritoRes = await pool.query(
    'SELECT cantidad FROM carrito WHERE idusuario=$1 AND idproducto=$2',
    [idusuario, idproducto]
  );
  const yaEnCarrito = carritoRes.rows[0]?.cantidad ?? 0;

  // 2. Verificar stock disponible en detallesproducto
  const stockRes = await pool.query(
    'SELECT cantidad FROM detallesproducto WHERE idproducto=$1',
    [idproducto]
  );
  const stockDisponible = stockRes.rows[0]?.cantidad ?? 0;

  const nuevaCantidad = yaEnCarrito + cantidad;

  if (nuevaCantidad > stockDisponible) {
    const error = new Error('Stock insuficiente');
    error.status = 409;
    throw error;
  }

  // 3. Insertar o actualizar producto en carrito
  if (yaEnCarrito > 0) {
    await pool.query(
      'UPDATE carrito SET cantidad=$1, updatedon=NOW() WHERE idusuario=$2 AND idproducto=$3',
      [nuevaCantidad, idusuario, idproducto]
    );
  } else {
    await pool.query(
      'INSERT INTO carrito (idusuario, idproducto, cantidad, createdon) VALUES ($1, $2, $3, NOW())',
      [idusuario, idproducto, cantidad]
    );
  }

  return { ok: true };
};

// 🛒 Obtener productos del carrito por usuario
exports.getByUsuario = async (idusuario) => {
  const result = await pool.query(`
    SELECT 
      p.idproducto,
      p.nombre,
      p.descripcion,
      p.imagen,
      p.precio,
      c.cantidad
    FROM carrito c
    JOIN productos p ON p.idproducto = c.idproducto
    WHERE c.idusuario = $1
      AND c.deletedon IS NULL
  `, [idusuario]);

  // 🔥 Convertir precio a número
  return result.rows.map(row => ({
    ...row,
    precio: Number(row.precio),
  }));
};

// ❌ Eliminar producto del carrito
exports.eliminarDelCarrito = async (idusuario, idproducto) => {
  const query = `
    DELETE FROM carrito
    WHERE idusuario = $1 AND idproducto = $2
  `;
  return pool.query(query, [idusuario, idproducto]); // ✅ corregido pool
};
