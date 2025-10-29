// src/modules/mail/mail.service.js
const pool = require('../../config/db');
const { sendRecoveryCode } = require('./mailer');

const CODE_TTL_MIN = Number(process.env.RECOVERY_CODE_TTL_MIN || 15);
const DRY_RUN = String(process.env.MAIL_DRY_RUN || 'false').toLowerCase() === 'true';

function sixDigit() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function findUserByEmail(email) {
  const { rows } = await pool.query(
    `SELECT idusuario, correo, codigorecuperacion, fechaexpiracion, deletedon
       FROM usuario
      WHERE correo = $1 AND deletedon IS NULL`,
    [email]
  );
  return rows[0] || null;
}

/** Guarda código y fecha de expiración */
async function persistCode(email, code, ttlMin = CODE_TTL_MIN) {
  const { rowCount } = await pool.query(
    `UPDATE usuario
        SET codigorecuperacion = $2,
            fechaexpiracion    = NOW() + ($3 || ' minutes')::interval,
            updatedon          = NOW()
      WHERE correo = $1 AND deletedon IS NULL`,
    [email, code, String(ttlMin)]
  );
  return rowCount > 0;
}

/** Limpia código (opcional tras reset) */
async function clearCode(email) {
  await pool.query(
    `UPDATE usuario
        SET codigorecuperacion = NULL,
            fechaexpiracion    = NULL,
            updatedon          = NOW()
      WHERE correo = $1 AND deletedon IS NULL`,
    [email]
  );
}

/** POST /mail/send-code y /mail/resend-code usan esto */
async function sendCode(email) {
  const user = await findUserByEmail(email);
  if (!user) return { ok: false, status: 404, error: 'Email no registrado' };

  const code = sixDigit();
  const saved = await persistCode(email, code, CODE_TTL_MIN);
  if (!saved) return { ok: false, status: 500, error: 'No se pudo guardar el código' };

  try {
    if (DRY_RUN) {
      console.log(`[MAIL][DRY_RUN] Enviaría a ${email} el código ${code} (TTL ${CODE_TTL_MIN}m)`);
    } else {
      await sendRecoveryCode(email, code, CODE_TTL_MIN);
    }
    return { ok: true, ttlMinutes: CODE_TTL_MIN };
  } catch (err) {
    console.error('Mailer error:', err);
    // Aun si falla el envío, el código está en BD; devolvemos 200 con warning opcional
    return { ok: true, ttlMinutes: CODE_TTL_MIN, warn: 'Código guardado pero no se pudo enviar el email' };
  }
}

/** Lee de BD y valida código + expiración */
async function verifyCode(email, code) {
  const user = await findUserByEmail(email);
  if (!user) return { ok: false, status: 404, error: 'Email no registrado' };

  if (!user.codigorecuperacion) {
    return { ok: false, status: 400, error: 'No hay un código activo para este email' };
  }
  if (user.codigorecuperacion !== code) {
    return { ok: false, status: 400, error: 'Código incorrecto' };
  }
  if (user.fechaexpiracion && new Date(user.fechaexpiracion) < new Date()) {
    return { ok: false, status: 400, error: 'Código expirado' };
  }
  return { ok: true };
}

/** Actualiza contraseña y limpia código (usa bcryptjs si quieres hashear) */
async function resetPassword(email, code, newPasswordHashedOrPlain) {
  // Si quieres hashear: const bcrypt = require('bcryptjs'); const hash = await bcrypt.hash(newPasswordHashedOrPlain, 10);
  const { rowCount } = await pool.query(
    `UPDATE usuario
        SET contrasena = $3,
            codigorecuperacion = NULL,
            fechaexpiracion    = NULL,
            updatedon          = NOW()
      WHERE correo = $1
        AND codigorecuperacion = $2
        AND (fechaexpiracion IS NULL OR fechaexpiracion > NOW())
        AND deletedon IS NULL`,
    [email, code, newPasswordHashedOrPlain]
  );
  return rowCount > 0
    ? { ok: true }
    : { ok: false, status: 400, error: 'Código inválido/expirado o correo no encontrado' };
}

module.exports = {
  sendCode,
  verifyCode,
  resetPassword,
  clearCode,
};
