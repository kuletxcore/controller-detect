// kxai-controller: the KuletXAI test site (kuletxcore/kuletxai-site, branch "test") with a
// controller logger built in, for screen recordings.
// - Pages: the site's own server (built from the repo), with the logger injected into <head>.
// - /assets/*: the built JS/CSS, bundled into this worker (see build.sh).
// - Everything else (images, music, video, fonts): fetched from the repo's public/ folder on GitHub.
import server from './server/index.js';
import { CLIENT, BUILT_FROM } from './client-manifest.js';
import logger from './logger.js.txt';

const RAW = `https://raw.githubusercontent.com/kuletxcore/kuletxai-site/${BUILT_FROM}/public`;
const LOGGER_PATH = '/__kx-logger.js';
const TYPES = {
  js: 'text/javascript; charset=utf-8', css: 'text/css; charset=utf-8', json: 'application/json',
  html: 'text/html; charset=utf-8', txt: 'text/plain; charset=utf-8', ico: 'image/x-icon', png: 'image/png',
  webp: 'image/webp', jpg: 'image/jpeg', svg: 'image/svg+xml', mp3: 'audio/mpeg', mp4: 'video/mp4',
  webm: 'video/webm', woff2: 'font/woff2', xml: 'application/xml', webmanifest: 'application/manifest+json',
};
const ext = (p) => (p.match(/\.([a-z0-9]+)$/i) || [])[1]?.toLowerCase();

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = decodeURIComponent(url.pathname);

    if (path === LOGGER_PATH) {
      return new Response(logger, { headers: { 'content-type': TYPES.js, 'cache-control': 'no-cache' } });
    }
    if (CLIENT[path] !== undefined) {
      return new Response(CLIENT[path], {
        headers: { 'content-type': TYPES[ext(path)] || 'application/octet-stream', 'cache-control': 'public, max-age=31536000, immutable' },
      });
    }
    // A file path that isn't a built asset: serve it from the repo's public/ folder
    // (includes .html: the intro cards are static pages in public/)
    if (ext(path)) {
      const res = await fetch(RAW + url.pathname, { cf: { cacheEverything: true, cacheTtl: 86400 } });
      if (res.ok) {
        const headers = new Headers({
          'content-type': TYPES[ext(path)] || 'application/octet-stream',
          'cache-control': 'public, max-age=86400',
          'access-control-allow-origin': '*',
        });
        const len = res.headers.get('content-length');
        if (len) headers.set('content-length', len);
        return new Response(res.body, { status: 200, headers });
      }
      if (res.status !== 404) return new Response(`upstream ${res.status}`, { status: 502 });
      // 404 there: let the app answer (it may own the path)
    }

    const res = await server.fetch(request, env, ctx);
    if (!(res.headers.get('content-type') || '').includes('text/html')) return res;
    const out = new Response(res.body, res);
    out.headers.set('cache-control', 'no-cache');
    return new HTMLRewriter()
      .on('head', { element(el) { el.prepend(`<script src="${LOGGER_PATH}"></script>`, { html: true }); } })
      .transform(out);
  },
};
