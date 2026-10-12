import { Resolver } from 'node:dns/promises';
import { AppError } from '../../utils/AppError.js';

// Most common typos -> the domain the user almost certainly meant.
const TYPO_DOMAINS = {
  'gmial.com': 'gmail.com',
  'gmai.com': 'gmail.com',
  'gamil.com': 'gmail.com',
  'gmail.con': 'gmail.com',
  'gmail.co': 'gmail.com',
  'gmil.com': 'gmail.com',
  'hotmial.com': 'hotmail.com',
  'hotmail.con': 'hotmail.com',
  'yaho.com': 'yahoo.com',
  'yahoo.con': 'yahoo.com',
  'outlok.com': 'outlook.com',
  'outlook.con': 'outlook.com',
  'icloud.con': 'icloud.com',
};

// Throw-away inbox providers: a code sent there proves nothing.
const DISPOSABLE_DOMAINS = new Set([
  'mailinator.com',
  'guerrillamail.com',
  '10minutemail.com',
  'tempmail.com',
  'temp-mail.org',
  'yopmail.com',
  'trashmail.com',
  'sharklasers.com',
  'throwawaymail.com',
]);

// "Domain does not exist / has no mail records" -> definite answer. Anything else
// (timeout, SERVFAIL, offline server) is NOT the user's fault, so we do not block them.
const DEFINITE_NO = new Set(['ENOTFOUND', 'ENODATA']);

function createDnsLookup() {
  const resolver = new Resolver({ timeout: 3000, tries: 2 });
  return {
    resolveMx: (domain) => resolver.resolveMx(domain),
    resolve4: (domain) => resolver.resolve4(domain),
    resolve6: (domain) => resolver.resolve6(domain),
  };
}

/**
 * Returns an async function that throws a 422 AppError when an address cannot
 * possibly receive mail. It checks the typo list, the disposable list and DNS
 * (MX, then A/AAAA as RFC 5321 allows).
 *
 * This proves the DOMAIN accepts email, not that the mailbox exists. Only the
 * verification code proves that.
 */
export function createEmailChecker({ dns = createDnsLookup(), logger = console } = {}) {
  return async function assertDeliverableEmail(email) {
    const domain = email.split('@')[1];

    const suggestion = TYPO_DOMAINS[domain];
    if (suggestion) {
      throw new AppError(
        422,
        'EMAIL_TYPO',
        `Did you mean ${email.split('@')[0]}@${suggestion}?`,
        { fields: { email: `Did you mean ${email.split('@')[0]}@${suggestion}?` }, suggestion },
      );
    }

    if (DISPOSABLE_DOMAINS.has(domain)) {
      throw new AppError(422, 'EMAIL_DISPOSABLE', 'Please use a permanent email address.', {
        fields: { email: 'Please use a permanent email address.' },
      });
    }

    const noMailDomain = () =>
      new AppError(422, 'EMAIL_DOMAIN_INVALID', `We can't send email to "${domain}". Check the address.`, {
        fields: { email: `We can't send email to "${domain}". Check the address.` },
      });

    try {
      const records = await dns.resolveMx(domain);
      if (Array.isArray(records) && records.length > 0) {
        // RFC 7505 "null MX": a single record with an empty exchange means "this domain accepts no mail".
        const onlyNull = records.length === 1 && (records[0].exchange === '' || records[0].exchange === '.');
        if (onlyNull) throw noMailDomain();
        return;
      }
    } catch (err) {
      if (err instanceof AppError) throw err;
      if (!DEFINITE_NO.has(err.code)) {
        logger.warn(`[email-check] DNS problem for ${domain} (${err.code}); letting the address through.`);
        return;
      }
      // No MX: fall through and try A/AAAA below.
    }

    try {
      const v4 = await dns.resolve4(domain).catch(() => []);
      const v6 = v4.length ? [] : await dns.resolve6(domain).catch(() => []);
      if (v4.length || v6.length) return;
    } catch {
      return;
    }
    throw noMailDomain();
  };
}