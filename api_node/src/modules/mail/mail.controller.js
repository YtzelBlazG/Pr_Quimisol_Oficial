// src/modules/mail/mail.controller.js
const service = require('./mail.service');

async function sendCode(req, res) {
  try {
    const { email } = req.body || {};
    if (!email) return res.status(400).json({ error: 'email requerido' });

    const r = await service.sendCode(email.trim());
    if (!r.ok) return res.status(r.status || 400).json({ error: r.error });
    return res.json({ message: r.warn || 'Código enviado', ttlMinutes: r.ttlMinutes });
  } catch (e) {
    console.error('❌ mail.sendCode:', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function resendCode(req, res) {
  return sendCode(req, res);
}

async function verifyCode(req, res) {
  try {
    console.log('[MAIL] /verify-code body:', req.body); // LOG para confirmar entrada
    const { email, code } = req.body || {};
    if (!email || !code) return res.status(400).json({ error: 'email y code requeridos' });

    const r = await service.verifyCode(email.trim(), code.trim());
    if (!r.ok) return res.status(r.status || 400).json({ error: r.error });
    return res.json({ valid: true });
  } catch (e) {
    console.error('❌ mail.verifyCode:', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function resetPassword(req, res) {
  try {
    const { email, code, newPassword } = req.body || {};
    if (!email || !code || !newPassword) {
      return res.status(400).json({ error: 'email, code y newPassword son requeridos' });
    }
    const r = await service.resetPassword(email.trim(), code.trim(), newPassword);
    if (!r.ok) return res.status(r.status || 400).json({ error: r.error });
    return res.json({ message: 'Contraseña actualizada' });
  } catch (e) {
    console.error('❌ mail.resetPassword:', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = { sendCode, resendCode, verifyCode, resetPassword };
