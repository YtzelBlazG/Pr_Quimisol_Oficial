const db = require('../../config/db');
const bcrypt = require('bcryptjs');

async function login(correo, contrasena) {
  const q = `
    SELECT u.idusuario, u.correo, u.rol, u.estado, u.contrasena,
           p.idpersona, p.nombre
    FROM usuario u
    JOIN persona p ON p.idpersona = u.idpersona
    WHERE u.correo = $1 AND u.deletedon IS NULL AND p.deletedon IS NULL
    LIMIT 1
  `;
  const { rows } = await db.query(q, [correo]);
  const user = rows[0];
  if (!user) return null;

  const ok = await bcrypt.compare(contrasena, user.contrasena || '');
  if (!ok) return null;

  return {
    idusuario: user.idusuario,
    correo: user.correo,
    rol: user.rol,
    estado: user.estado,
    idpersona: user.idpersona,
    nombre: user.nombre,
  };
}

async function register({ nombre, correo, contrasena }) {
  return db.withTransaction(async (client) => {
    const p = await client.query(
      `INSERT INTO persona (nombre, telefono) VALUES ($1, NULL) RETURNING idpersona`,
      [nombre]
    );
    const idpersona = p.rows[0].idpersona;

    const hash = await bcrypt.hash(contrasena, 10);

    await client.query(
      `INSERT INTO usuario (idpersona, correo, contrasena, rol, estado)
       VALUES ($1, $2, $3, 'cliente', 'activo')`,
      [idpersona, correo, hash]
    );

    return { ok: true, idpersona, correo };
  });
}

module.exports = { login, register };
