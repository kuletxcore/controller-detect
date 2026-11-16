#!/usr/bin/env bash
# Builds kuletxai-site (branch "test" by default) and deploys it as the "kxai-controller"
# worker with the controller logger injected. Usage: kxai/build.sh [branch]
# Needs: git, node/npm, curl, python3. Cloudflare auth comes from CF_API_TOKEN, or from a
# proxy that injects it (pass a dummy token then).
set -euo pipefail
BRANCH="${1:-test}"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${KX_WORK:-$(mktemp -d)}"
ACCOUNT="${CF_ACCOUNT_ID:-45dd08fff09f48cb97a56accf8ea85fa}"
NAME="kxai-controller"
API="https://api.cloudflare.com/client/v4/accounts/$ACCOUNT/workers"

echo "== clone kuletxai-site@$BRANCH into $WORK/site"
rm -rf "$WORK/site"
GIT_LFS_SKIP_SMUDGE=1 git clone -q --depth 1 -b "$BRANCH" https://github.com/kuletxcore/kuletxai-site "$WORK/site"
SHA="$(git -C "$WORK/site" rev-parse HEAD)"

echo "== build"
( cd "$WORK/site" && (npm ci --no-audit --no-fund --ignore-scripts >/dev/null 2>&1 || npm install --no-audit --no-fund --ignore-scripts >/dev/null) && npx vite build >/dev/null )

echo "== bundle"
OUT="$WORK/out"
rm -rf "$OUT" && mkdir -p "$OUT/server" "$OUT/client"
( cd "$WORK/site/dist/server" && find . -name '*.js' | while read -r f; do mkdir -p "$OUT/server/$(dirname "$f")"; cp "$f" "$OUT/server/$f"; done )
cp "$HERE/worker.js" "$HERE/logger.js.txt" "$OUT/"
python3 - "$WORK/site/dist/client" "$OUT" "$SHA" <<'PY'
import os, sys, json
client, out, sha = sys.argv[1:]
lines, entries = [], []
for root, _, files in os.walk(os.path.join(client, 'assets')):
    for f in sorted(files):
        if f.endswith('.map'): continue
        src = os.path.join(root, f)
        rel = '/' + os.path.relpath(src, client).replace(os.sep, '/')
        mod = 'client' + rel + '.txt'
        os.makedirs(os.path.dirname(os.path.join(out, mod)), exist_ok=True)
        with open(src, 'rb') as a, open(os.path.join(out, mod), 'wb') as b: b.write(a.read())
        n = len(lines)
        lines.append(f"import c{n} from './{mod}';")
        entries.append(f"  {json.dumps(rel)}: c{n},")
with open(os.path.join(out, 'client-manifest.js'), 'w') as fh:
    fh.write('\n'.join(lines) + f"\nexport const BUILT_FROM = {json.dumps(sha)};\nexport const CLIENT = {{\n" + '\n'.join(entries) + '\n};\n')
print(f"{len(entries)} client assets, built from {sha[:7]}")
PY

echo "== deploy $NAME"
cd "$OUT"
printf '{"main_module":"worker.js","compatibility_date":"2025-09-02","compatibility_flags":["nodejs_compat"]}' > metadata.json
ARGS=(-F "metadata=@metadata.json;type=application/json")
while read -r f; do
  f="${f#./}"
  case "$f" in
    metadata.json) ;;
    *.js) ARGS+=(-F "$f=@$f;filename=$f;type=application/javascript+module") ;;
    *.txt) ARGS+=(-F "$f=@$f;filename=$f;type=text/plain") ;;
  esac
done < <(find . -type f)
curl -sS -X PUT "$API/scripts/$NAME" -H "Authorization: Bearer ${CF_API_TOKEN:-proxy-injected}" "${ARGS[@]}" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('deploy ok' if d['success'] else d['errors']); sys.exit(0 if d['success'] else 1)"
curl -sS -X POST "$API/scripts/$NAME/subdomain" -H "Authorization: Bearer ${CF_API_TOKEN:-proxy-injected}" \
  -H 'content-type: application/json' -d '{"enabled":true,"previews_enabled":false}' >/dev/null
echo "== live: https://$NAME.kuletxcore.workers.dev (kuletxai-site@$BRANCH ${SHA:0:7})"
