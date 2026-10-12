const escapeHtml = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

export function codeEmail({ name, code, purpose, expiresInMinutes }) {
  const isReset = purpose === 'reset_password';
  const subject = isReset ? 'Your password reset code' : 'Your email verification code';
  const intro = isReset
    ? 'Use this code to reset your AI Education password:'
    : 'Use this code to verify your email for AI Education:';
  const outro = `It expires in ${expiresInMinutes} minutes. If you did not request it, you can ignore this email.`;

  const text = `Hi ${name},\n\n${intro}\n\n${code}\n\n${outro}\n`;
  const html = `<div style="font-family:Arial,sans-serif;max-width:480px;margin:auto">
  <p>Hi ${escapeHtml(name)},</p>
  <p>${intro}</p>
  <p style="font-size:32px;letter-spacing:8px;font-weight:bold;margin:24px 0">${escapeHtml(code)}</p>
  <p style="color:#555">${outro}</p>
</div>`;
  return { subject, text, html };
}