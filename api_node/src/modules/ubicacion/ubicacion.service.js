const pool = require("../../config/db");

async function listByPersona(idpersona) {
  const { rows } = await pool.query(
    "SELECT * FROM ubicacion WHERE idpersona=$1 AND deletedon IS NULL ORDER BY idubicacion DESC",
    [idpersona]
  );
  return rows;
}

async function add(idpersona, { nombre, latitud, longitud, direccion, ciudad }) {
  const { rows } = await pool.query(
    `INSERT INTO ubicacion (idpersona, nombre, latitud, longitud, direccion, ciudad)
     VALUES ($1,$2,$3,$4,$5,$6)
     RETURNING *`,
    [idpersona, nombre, latitud, longitud, direccion, ciudad]
  );
  return rows[0];
}

async function update(idubicacion, { nombre, latitud, longitud, direccion, ciudad }) {
  const { rowCount, rows } = await pool.query(
    `UPDATE ubicacion
     SET nombre=$2, latitud=$3, longitud=$4, direccion=$5, ciudad=$6, updatedon=NOW()
     WHERE idubicacion=$1 AND deletedon IS NULL
     RETURNING *`,
    [idubicacion, nombre, latitud, longitud, direccion, ciudad]
  );
  return rowCount ? rows[0] : null;
}

async function remove(idubicacion) {
  const { rowCount } = await pool.query(
    "UPDATE ubicacion SET deletedon=NOW() WHERE idubicacion=$1",
    [idubicacion]
  );
  return rowCount > 0;
}

module.exports = { listByPersona, add, update, remove };
