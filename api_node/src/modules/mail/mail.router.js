// src/modules/mail/mail.router.js
const router = require('express').Router();
const ctrl = require('./mail.controller');

router.post('/send-code', ctrl.sendCode);
router.post('/resend-code', ctrl.resendCode);
router.post('/verify-code', ctrl.verifyCode);
router.post('/reset-password', ctrl.resetPassword);

// útil para probar conectividad
router.get('/ping', (_req, res) => res.json({ ok: true, t: Date.now() }));

module.exports = router;
