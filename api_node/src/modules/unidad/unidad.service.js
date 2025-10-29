// Servicio de UNIDADES: consultas a Postgres vía tu pool
const pool = require('../../config/db');

// Listar unidades activas
async function list() {
  const { rows } = await pool.query(
    'SELECT * FROM unidades WHERE deletedon IS NULL ORDER BY idunidad ASC'
  );
  return rows;
}

// Obtener una unidad por ID
async function getById(id) {
  const { rows } = await pool.query(
    'SELECT * FROM unidades WHERE idunidad = $1 AND deletedon IS NULL',
    [id]
  );
  return rows[0] || null;
}

// Crear unidad (createdon lo pone el backend)
async function create({ nombre, descripcion }) {
  const { rows } = await pool.query(
    `INSERT INTO unidades (nombre, descripcion, createdon)
     VALUES ($1, $2, NOW())
     RETURNING *`,
    [nombre, descripcion]
  );
  return rows[0];
}

// Actualizar unidad (updatedon lo pone el backend)
async function update(id, { nombre, descripcion }) {
  const { rows } = await pool.query(
    `UPDATE unidades
     SET nombre = $1, descripcion = $2, updatedon = NOW()
     WHERE idunidad = $3
     RETURNING *`,
    [nombre, descripcion, id]
  );
  return rows[0] || null;
}

// Borrado lógico
async function remove(id) {
  const { rowCount } = await pool.query(
    'UPDATE unidades SET deletedon = NOW() WHERE idunidad = $1',
    [id]
  );
  return rowCount > 0;
}

module.exports = { list, getById, create, update, remove };
