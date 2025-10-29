const db = require('../../config/db');

exports.list = async () => {
  const result = await db.query('SELECT * FROM detallesproducto WHERE deletedon IS NULL');
  return result.rows;
};

exports.getById = async (id) => {
  const result = await db.query(
    'SELECT * FROM detallesproducto WHERE id = $1 AND deletedon IS NULL',
    [id]
  );
  return result.rows[0];
};

exports.create = async ({ idproducto, atributo, valor, cantidad }) => {
  const result = await db.query(
    `INSERT INTO detallesproducto (idproducto, atributo, valor, cantidad) 
     VALUES ($1, $2, $3, $4) RETURNING *`,
    [idproducto, atributo, valor, cantidad]
  );
  return result.rows[0];
};

exports.update = async (id, { atributo, valor, cantidad }) => {
  const result = await db.query(
    `UPDATE detallesproducto 
     SET atributo = $1, valor = $2, cantidad = $3, updatedon = CURRENT_TIMESTAMP 
     WHERE id = $4 RETURNING *`,
    [atributo, valor, cantidad, id]
  );
  return result.rows[0];
};

exports.remove = async (id) => {
  await db.query(
    `UPDATE detallesproducto 
     SET deletedon = CURRENT_TIMESTAMP 
     WHERE id = $1`,
    [id]
  );
};
