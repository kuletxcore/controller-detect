import html from './index.html';
import profile from './gtnx-split-profile.json';

export default {
  async fetch(request) {
    const { pathname } = new URL(request.url);
    if (pathname === '/gtnx-split-profile.json') {
      return new Response(profile, {
        headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-cache', 'access-control-allow-origin': '*' },
      });
    }
    return new Response(html, {
      headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-cache' },
    });
  },
};
