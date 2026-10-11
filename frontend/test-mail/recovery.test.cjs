const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const original = Module._load;
let deliveries = [];
Module._load = function(name, ...args) {
  if (name === 'nodemailer') return { createTransport: () => ({ sendMail: async mail => deliveries.push(mail), close() {} }) };
  return original.call(this, name, ...args);
};
const handler = require('../api/recovery-email.js');
Module._load = original;
const invoke = async (method, secret, body) => {
  const result = {};
  const res = { setHeader() {}, status(code) { result.status = code; return this; }, json(body) { result.body = body; return this; } };
  await handler({ method, headers: { authorization: secret ? `Bearer ${secret}` : '' }, body }, res);
  return result;
};
test('mail endpoint rejects public callers and malformed tokens', async () => {
  process.env.RECOVERY_MAIL_SECRET = 'test-only-secret';
  assert.equal((await invoke('GET')).status, 405);
  assert.equal((await invoke('POST')).status, 401);
  assert.equal((await invoke('POST', 'test-only-secret', { email: 'person@example.com', token: 'bad' })).status, 400);
  assert.equal(deliveries.length, 0);
});
test('configured mail sends only the fixed recovery template', async () => {
  process.env.MAIL_USERNAME = 'sender@example.com';
  process.env.MAIL_PASSWORD = 'test-only-password';
  const result = await invoke('POST', 'test-only-secret', { email: 'person@example.com', token: 'a'.repeat(64) });
  assert.equal(result.status, 200);
  assert.equal(deliveries.length, 1);
  assert.equal(deliveries[0].to, 'person@example.com');
  assert.ok(deliveries[0].text.includes('/#reset_token='));
});
