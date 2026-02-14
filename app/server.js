/**
 * Minimal app for 3-tier stack.
 * - GET /       -> { message }
 * - GET /health -> { status: "ok" } (for ALB health checks)
 * - GET /db     -> fetches DB secret from Secrets Manager, returns { db: "reachable" | "error" } (no credentials in response)
 */

const express = require('express');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const PORT = Number(process.env.PORT) || 80;
const app = express();

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const status = res.statusCode;
    const msg = `${req.method} ${req.url} ${status} ${Date.now() - start}ms`;
    console.log(msg);
    if (status >= 500) console.error('ERROR', msg);
    if (status >= 400 && status < 500) console.warn('WARN', msg);
  });
  next();
});

app.get('/', (req, res) => {
  res.json({ message: 'Three-tier app', env: process.env.ENVIRONMENT || 'dev' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'app' });
});

app.get('/db', async (req, res) => {
  const secretName = process.env.DB_SECRET_ARN || process.env.DB_SECRET_NAME;
  if (!secretName) {
    return res.status(200).json({ db: 'not_configured' });
  }
  try {
    const client = new SecretsManagerClient({ region: process.env.AWS_REGION || 'ap-south-1' });
    const cmd = new GetSecretValueCommand({
      SecretId: secretName,
    });
    await client.send(cmd);
    res.json({ db: 'reachable' });
  } catch (err) {
    console.error('DB secret fetch failed', err.message);
    res.status(500).json({ db: 'error', message: err.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Listening on port ${PORT}`);
});
