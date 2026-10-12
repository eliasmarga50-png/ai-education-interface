import { codeEmail } from './templates.js';

const RESEND_URL = 'https://api.resend.com/emails';

/**
 * mode "resend":  Resend HTTP API. Plain fetch, no package, works on serverless.
 * mode "smtp":    any SMTP server through nodemailer (loaded lazily, so other modes need no install).
 * mode "console": prints the email in the terminal (development only, refused in production by the config).
 *
 * sendCode() throws when delivery fails; the auth service turns that into a visible
 * "we couldn't send the email" message and logs err.message (which never contains a key).
 */
export function createMailer(mailConfig, logger = console, fetchImpl = fetch) {
  if (mailConfig.mode === 'console') {
    return {
      async sendCode(opts) {
        const { subject, text } = codeEmail(opts);
        logger.log(
          `\n┌─ DEV EMAIL ─────────────────────────────\n│ To:      ${opts.to}\n│ Subject: ${subject}\n│ Code:    ${opts.code}\n└─────────────────────────────────────────\n`,
        );
        return { text };
      },
    };
  }

  if (mailConfig.mode === 'resend') {
    return {
      async sendCode(opts) {
        const { subject, text, html } = codeEmail(opts);

        let res;
        try {
          res = await fetchImpl(RESEND_URL, {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${mailConfig.resendApiKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ from: mailConfig.from, to: [opts.to], subject, text, html }),
            signal: AbortSignal.timeout(10_000),
          });
        } catch (err) {
          const timedOut = err?.name === 'TimeoutError' || err?.name === 'AbortError';
          throw new Error(timedOut ? 'Resend did not answer within 10 seconds' : `Resend is unreachable (${err?.message})`);
        }

        if (!res.ok) {
          // Resend explains problems in the body, for example an unverified sending domain.
          let detail = '';
          try {
            const body = await res.json();
            detail = body?.message || body?.name || '';
          } catch {
            // body was not JSON
          }
          throw new Error(`Resend rejected the email (HTTP ${res.status})${detail ? `: ${detail}` : ''}`);
        }
      },
    };
  }

  let transporterPromise = null;
  const getTransporter = () =>
    (transporterPromise ??= import('nodemailer').then(({ default: nodemailer }) =>
      nodemailer.createTransport({
        host: mailConfig.host,
        port: mailConfig.port,
        secure: mailConfig.port === 465,
        auth: { user: mailConfig.user, pass: mailConfig.pass },
        connectionTimeout: 10_000,
        socketTimeout: 15_000,
      }),
    ));

  return {
    async sendCode(opts) {
      const { subject, text, html } = codeEmail(opts);
      const transporter = await getTransporter();
      await transporter.sendMail({ from: mailConfig.from, to: opts.to, subject, text, html });
    },
  };
}