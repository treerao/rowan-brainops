const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

const app = express();
app.disable('x-powered-by');
app.use(helmet({ contentSecurityPolicy: false }));
app.use(morgan('combined'));

const workspaceRoot = process.env.WORKSPACE_ROOT || '/workspace';
const allowlist = (process.env.ROWAN_WEB_ALLOWLIST || 'apps')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean)
  .filter((s) => !s.includes('..') && !path.isAbsolute(s));
const indexPath = process.env.ROWAN_WEB_INDEX || '/apps/tasks/';
const port = Number(process.env.ROWAN_WEB_PORT || 3333);

app.get('/healthz', (_req, res) => {
  res.json({ ok: true, allowlist, workspaceRoot });
});

for (const segment of allowlist) {
  const dir = path.join(workspaceRoot, segment);
  if (!fs.existsSync(dir)) {
    continue;
  }
  app.use(`/${segment}`, express.static(dir, { fallthrough: true, index: ['index.html'] }));
}

app.get('/', (_req, res) => {
  res.redirect(indexPath);
});

app.use((_req, res) => {
  res.status(404).json({
    error: 'Not found',
    allowedRoots: allowlist.map((segment) => `/${segment}`),
  });
});

app.listen(port, () => {
  console.log(`rowan-web listening on ${port}`);
});
