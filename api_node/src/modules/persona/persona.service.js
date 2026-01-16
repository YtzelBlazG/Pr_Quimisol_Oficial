const db = require('../../config/db');

async function list() {
  const { rows } = await db.query(
    `SELECT idpersona, nombre, telefono, createdon, updatedon, deletedon
     FROM persona
     WHERE deletedon IS NULL
     ORDER BY idpersona DESC`
  );
  return rows;
}

async function getById(id) {
  const { rows } = await db.query(
    `SELECT idpersona, nombre, telefono, createdon, updatedon, deletedon
     FROM persona
     WHERE idpersona=$1 AND deletedon IS NULL`,
    [id]
  );
  return rows[0] || null;
}

async function update(id, { nombre, telefono }) {
  const { rows } = await db.query(
    `UPDATE persona
     SET nombre=$2, telefono=$3, updatedon=NOW()
     WHERE idpersona=$1
     RETURNING idpersona, nombre, telefono, createdon, updatedon, deletedon`,
    [id, nombre, telefono]
  );
  return rows[0];
}

async function remove(id) {
  const { rowCount } = await db.query(
    `UPDATE persona
     SET deletedon=NOW()
     WHERE idpersona=$1`,
    [id]
  );
  return rowCount > 0;
}

module.exports = { list, getById, update, remove };
