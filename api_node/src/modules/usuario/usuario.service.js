// src/modules/usuario/usuario.service.js
const db = require('../../config/db');
const bcrypt = require('bcryptjs');

async function list({ page = 1, limit = 50, search = '' } = {}) {
  const off = (Number(page) > 0 ? Number(page) - 1 : 0) * Number(limit);
  const params = [];
  let where = 'u.deletedon IS NULL';

  if (search && search.trim()) {
    params.push(`%${search.trim()}%`);
    where += ` AND (p.nombre ILIKE $${params.length} OR u.correo ILIKE $${params.length})`;
  }

  const items = await db.query(
    `
    SELECT u.idusuario, u.idpersona, p.nombre, u.correo, u.rol, u.estado,
           u.createdon, u.updatedon
    FROM usuario u
    JOIN persona p ON p.idpersona = u.idpersona
    WHERE ${where}
    ORDER BY u.idusuario DESC
    LIMIT ${Number(limit)} OFFSET ${off}
    `,
    params
  ).then(r => r.rows);

  const total = await db.query(
    `
    SELECT COUNT(*)::int AS total
    FROM usuario u
    JOIN persona p ON p.idpersona = u.idpersona
    WHERE ${where}
    `,
    params
  ).then(r => r.rows[0].total);

  return { items, page: Number(page), limit: Number(limit), total };
}

async function register({ nombre, correo, password, telefono = null, rol = 'cliente' }) {
  const exists = await db.query(`SELECT 1 FROM usuario WHERE correo=$1 LIMIT 1`, [correo]);
  if (exists.rowCount > 0) {
    const err = new Error('Correo ya registrado');
    err.code = 'EMAIL_EXISTS';
    throw err;
  }

  const hash = await bcrypt.hash(password, 10);

  return db.withTransaction(async (client) => {
    const p = await client.query(
      `INSERT INTO persona (nombre, telefono, createdon)
       VALUES ($1,$2,NOW())
       RETURNING idpersona`,
      [nombre, telefono]
    );

    await client.query(
      `INSERT INTO usuario (idpersona, correo, contrasena, rol, estado, createdon)
       VALUES ($1,$2,$3,$4,'activo',NOW())`,
      [p.rows[0].idpersona, correo, hash, rol]
    );

    return { idpersona: p.rows[0].idpersona, correo };
  });
}

async function login({ correo, password }) {
  const u = await db.query(
    `SELECT u.idusuario, u.idpersona, u.correo, u.contrasena,
            COALESCE(u.rol,'cliente') AS rol, p.nombre
     FROM usuario u
     JOIN persona p ON p.idpersona = u.idpersona
     WHERE u.correo=$1 AND u.deletedon IS NULL AND p.deletedon IS NULL
     LIMIT 1`,
    [correo]
  );
  if (u.rowCount === 0) {
    const err = new Error('Credenciales inválidas');
    err.code = 'INVALID_CREDENTIALS';
    throw err;
  }
  const row = u.rows[0];
  const ok = await bcrypt.compare(password, row.contrasena);
  if (!ok) {
    const err = new Error('Credenciales inválidas');
    err.code = 'INVALID_CREDENTIALS';
    throw err;
  }
  return {
    usuario: {
      idusuario: row.idusuario,
      idpersona: row.idpersona,
      nombre: row.nombre,
      correo: row.correo,
      rol: String(row.rol).toLowerCase(),
    },
  };
}

module.exports = { list, register, login };
