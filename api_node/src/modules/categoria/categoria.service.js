// Servicio de CATEGORÍAS: consultas a Postgres vía pool
const pool = require('../../config/db');

// Listar categorías activas
async function list() {
  const { rows } = await pool.query(
    'SELECT * FROM categorias WHERE deletedon IS NULL ORDER BY id ASC'
  );
  return rows;
}

// Obtener una categoría por ID
async function getById(id) {
  const { rows } = await pool.query(
    'SELECT * FROM categorias WHERE id = $1 AND deletedon IS NULL',
    [id]
  );
  return rows[0] || null;
}

// Crear categoría (createdon lo pone el backend)
async function create({ nombre, descripcion }) {
  const { rows } = await pool.query(
    `INSERT INTO categorias (nombre, descripcion, createdon)
     VALUES ($1, $2, NOW())
     RETURNING *`,
    [nombre, descripcion]
  );
  return rows[0];
}

// Actualizar categoría (updatedon lo pone el backend)
async function update(id, { nombre, descripcion }) {
  const { rows } = await pool.query(
    `UPDATE categorias
     SET nombre = $1, descripcion = $2, updatedon = NOW()
     WHERE id = $3
     RETURNING *`,
    [nombre, descripcion, id]
  );
  return rows[0] || null;
}

// Borrado lógico
async function remove(id) {
  const { rowCount } = await pool.query(
    'UPDATE categorias SET deletedon = NOW() WHERE id = $1',
    [id]
  );
  return rowCount > 0;
}

module.exports = { list, getById, create, update, remove };
