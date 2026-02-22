const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');
const { marked } = require('marked');
const hljs = require('highlight.js');

const app = express();
app.disable('x-powered-by');
app.use(helmet({ contentSecurityPolicy: false }));
app.use(morgan('combined'));

const workspaceRoot = process.env.WORKSPACE_ROOT || '/workspace';
const allowlistRaw = process.env.ROWAN_WEB_ALLOWLIST || 'apps';
const allowlist = allowlistRaw
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean)
  .filter((s) => !s.includes('..') && !path.isAbsolute(s));
const fullWorkspaceMode = ['*', 'all'].includes(allowlistRaw.trim().toLowerCase());
const indexPath = process.env.ROWAN_WEB_INDEX || '/apps/tasks/';
const port = Number(process.env.ROWAN_WEB_PORT || 3333);

marked.setOptions({
  highlight: (code, lang) => {
    if (lang && hljs.getLanguage(lang)) {
      return hljs.highlight(code, { language: lang }).value;
    }
    return hljs.highlightAuto(code).value;
  },
});

const style = `
  body { max-width: 920px; margin: 40px auto; padding: 0 20px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; color: #e8e8e8; background: #111827; line-height: 1.65; }
  h1, h2, h3 { border-bottom: 1px solid #374151; padding-bottom: 0.3em; }
  a { color: #93c5fd; text-decoration: none; }
  a:hover { text-decoration: underline; }
  code { background: #1f2937; padding: 2px 6px; border-radius: 4px; }
  pre { background: #0b1220; border: 1px solid #374151; border-radius: 8px; padding: 16px; overflow-x: auto; }
  pre code { background: none; padding: 0; }
  blockquote { border-left: 4px solid #60a5fa; margin: 0; padding: 0 1em; color: #c7d2fe; }
  img { max-width: 100%; border-radius: 6px; }
  table { border-collapse: collapse; width: 100%; margin: 1em 0; }
  th, td { border: 1px solid #374151; padding: 8px 10px; text-align: left; }
  th { background: #1f2937; }
`;

function resolveWorkspaceFile(urlPath) {
  const decoded = decodeURIComponent(urlPath);
  const rel = decoded.replace(/^\/+/, '');
  const fsPath = path.resolve(workspaceRoot, rel);
  if (!fsPath.startsWith(path.resolve(workspaceRoot))) {
    return null;
  }
  return fsPath;
}

app.get('/healthz', (_req, res) => {
  res.json({ ok: true, allowlist: fullWorkspaceMode ? '*' : allowlist, workspaceRoot });
});

// Render markdown files as HTML (use ?raw=1 to get plain file content from static layer).
app.get('*.md', (req, res, next) => {
  if (req.query.raw !== undefined) {
    return next();
  }
  const fsPath = resolveWorkspaceFile(req.path);
  if (!fsPath || !fs.existsSync(fsPath)) {
    return next();
  }
  try {
    const raw = fs.readFileSync(fsPath, 'utf-8');
    const html = marked.parse(raw);
    const title = path.basename(fsPath);
    return res.status(200).type('html').send(`<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title><style>${style}</style><link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.10.0/styles/github-dark.min.css"></head><body>${html}</body></html>`);
  } catch (_err) {
    return next();
  }
});

if (fullWorkspaceMode) {
  app.use('/', express.static(workspaceRoot, { fallthrough: true, index: ['index.html'] }));
} else {
  for (const segment of allowlist) {
    const dir = path.join(workspaceRoot, segment);
    if (!fs.existsSync(dir)) {
      continue;
    }
    app.use(`/${segment}`, express.static(dir, { fallthrough: true, index: ['index.html'] }));
  }
}

app.get('/', (_req, res) => {
  res.redirect(indexPath);
});

app.use((_req, res) => {
  res.status(404).json({
    error: 'Not found',
    allowedRoots: fullWorkspaceMode ? 'all workspace paths' : allowlist.map((segment) => `/${segment}`),
  });
});

app.listen(port, () => {
  console.log(`rowan-web listening on ${port}`);
});
