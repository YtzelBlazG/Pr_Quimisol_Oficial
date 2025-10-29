const nodemailer = require('nodemailer');

const DRY_RUN = String(process.env.MAIL_DRY_RUN || 'false').toLowerCase() === 'true';

const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST, // smtp.gmail.com
  port: 465,
  secure: true,
  auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS },
});

if (process.env.NODE_ENV !== 'production') {
  console.log('[MAIL] HOST:', process.env.MAIL_HOST);
  console.log('[MAIL] USER:', process.env.MAIL_USER);
  console.log('[MAIL] FROM:', process.env.MAIL_FROM);
  transporter.verify()
    .then(() => console.log('[MAIL] SMTP listo'))
    .catch(err => console.error('[MAIL] SMTP error:', err));
}

async function sendRecoveryCode(to, code, ttlMinutes = 15) {
  if (DRY_RUN) {
    console.log(`[MAIL][DRY_RUN] Enviaría a ${to} el código ${code} (TTL ${ttlMinutes}m)`);
    return;
  }
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to,
    subject: 'Código de recuperación',
    html: `
      <div style="font-family:system-ui,-apple-system,Segoe UI,Roboto">
        <h2 style="margin:0 0 8px">Recuperación de acceso</h2>
        <p>Usa este código para continuar:</p>
        <div style="font-size:32px;letter-spacing:6px;font-family:monospace;margin:16px 0">
          <b>${code}</b>
        </div>
        <p style="color:#555">Expira en <b>${ttlMinutes} minutos</b>.</p>
      </div>
    `,
  });
}

module.exports = { sendRecoveryCode };
