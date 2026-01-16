const db = require('../../config/db');

// 🔹 Obtener todos los productos favoritos (solo para debug o admin)
exports.list = async () => {
  const result = await db.query(`
    SELECT p.*, f.idusuario
    FROM favoritos f
    JOIN productos p ON f.idproducto = p.idproducto
    WHERE f.deletedon IS NULL
  `);
  return result.rows;
};

// 🔹 Crear nuevo favorito
exports.create = async ({ idusuario, idproducto }) => {
  // Evitar duplicados
  const existe = await db.query(
    `SELECT 1 FROM favoritos WHERE idusuario = $1 AND idproducto = $2 AND deletedon IS NULL`,
    [idusuario, idproducto]
  );

  if (existe.rows.length > 0) {
    return { message: 'Ya está en favoritos' };
  }

  const result = await db.query(
    `INSERT INTO favoritos (idusuario, idproducto)
     VALUES ($1, $2)
     RETURNING *`,
    [idusuario, idproducto]
  );
  return result.rows[0];
};

// 🔹 Obtener favoritos por usuario
exports.getByUsuario = async (idusuario) => {
  const result = await db.query(
    `
    SELECT p.*
    FROM favoritos f
    JOIN productos p ON f.idproducto = p.idproducto
    WHERE f.deletedon IS NULL AND f.idusuario = $1
    `,
    [idusuario]
  );
  return result.rows;
};

// 🔹 Eliminar favorito (toggle off)
exports.delete = async (idusuario, idproducto) => {
  await db.query(
    `DELETE FROM favoritos WHERE idusuario = $1 AND idproducto = $2`,
    [idusuario, idproducto]
  );
};
