const { timingSafeEqual } = require('node:crypto');
const nodemailer = require('nodemailer');

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  const expected = process.env.RECOVERY_MAIL_SECRET;
  const supplied = (req.headers.authorization || '').replace(/^Bearer /, '');
  const actualBytes = Buffer.from(supplied);
  const expectedBytes = Buffer.from(expected || '');
  if (!expected || actualBytes.length !== expectedBytes.length || !timingSafeEqual(actualBytes, expectedBytes)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const { email, token } = req.body || {};
  if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || typeof token !== 'string' || !/^[A-Za-z0-9_-]{64}$/.test(token)) {
    return res.status(400).json({ error: 'Invalid recovery request' });
  }
  if (!process.env.MAIL_USERNAME || !process.env.MAIL_PASSWORD) return res.status(503).json({ error: 'Email is not configured' });
  const transport = nodemailer.createTransport({
    host: 'smtp.gmail.com', port: 465, secure: true,
    auth: { user: process.env.MAIL_USERNAME, pass: process.env.MAIL_PASSWORD },
    connectionTimeout: 15000, greetingTimeout: 15000, socketTimeout: 20000,
    disableFileAccess: true, disableUrlAccess: true,
  });
  const base = process.env.FRONTEND_URL || 'https://jaydeo-trav-planner.vercel.app';
  const link = `${base.replace(/\/$/, '')}/#reset_token=${encodeURIComponent(token)}`;
  try {
    await transport.sendMail({
      from: `trav. <${process.env.MAIL_USERNAME}>`, to: email,
      subject: 'Choose a new password for trav.',
      text: `Choose your trav. password using this link:\n\n${link}\n\nThis link expires in 30 minutes and can be used once. If you did not request it, you can ignore this email.`,
    });
    return res.status(200).json({ success: true });
  } catch (_) {
    return res.status(503).json({ error: 'Email delivery is temporarily unavailable' });
  } finally { transport.close(); }
};
