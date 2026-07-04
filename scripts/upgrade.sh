#!/usr/bin/env bash
#
# Upgrade this standalone fork to a new upstream JBrowse tag.
#
# DESTRUCTIVE — run from a clean working tree only.
# This script `rm -rf`s src/, scripts/, public/, webpack/, and tsconfig.json
# before re-copying from the upstream tag. Any uncommitted changes in those
# paths will be lost.
#
# Known footguns (verified against v4.1.14, see README "Upgrading"):
#   - Removes scripts/upgrade.sh itself (its self-backup step runs after the
#     rm and fails silently). Restore with `git checkout HEAD -- scripts/upgrade.sh`.
#   - Wipes public/config.json (not part of upstream products/jbrowse-web/public/).
#     Restore with `git checkout HEAD -- public/config.json`.
#
# Not idempotent: re-running against the same tag fails at the patch step,
# since inputs are already patched. If you need to re-run, reset to a clean tree.

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version-tag>  (e.g. v4.2.0)"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="/tmp/jbrowse-src"

echo "Cloning jbrowse-components at $VERSION..."
rm -rf "$TMP"
git clone --depth 1 --branch "$VERSION" https://github.com/GMOD/jbrowse-components.git "$TMP"

echo "Replacing source files..."
rm -rf "$REPO_ROOT/src" "$REPO_ROOT/scripts" "$REPO_ROOT/public" "$REPO_ROOT/webpack" "$REPO_ROOT/tsconfig.json"
cp -r "$TMP/products/jbrowse-web/src" "$REPO_ROOT/"
cp -r "$TMP/products/jbrowse-web/scripts" "$REPO_ROOT/"
cp -r "$TMP/products/jbrowse-web/public" "$REPO_ROOT/"
cp "$TMP/products/jbrowse-web/tsconfig.json" "$REPO_ROOT/"
cp -r "$TMP/webpack" "$REPO_ROOT/"

echo "Removing test files..."
rm -rf "$REPO_ROOT/public/test_data" "$REPO_ROOT/public/umd_plugin.js"
rm -rf "$REPO_ROOT/src/tests" "$REPO_ROOT/src/__snapshots__" "$REPO_ROOT/src/rootModel/__snapshots__"
rm -f "$REPO_ROOT/src/"*.test.ts "$REPO_ROOT/src/rootModel/"*.test.ts

echo "Re-copying this upgrade script..."
cp "$REPO_ROOT/scripts/upgrade.sh" /tmp/upgrade.sh.bak || true

echo "Patching package.json workspace deps to $VERSION..."
SEM="${VERSION#v}"
sed -i "s/\"workspace:\^\"/\"^${SEM}\"/g" "$REPO_ROOT/package.json" 2>/dev/null || \
  sed -i '' "s/\"workspace:\^\"/\"^${SEM}\"/g" "$REPO_ROOT/package.json"

echo "Patching script import paths..."
sed -i 's|../../../webpack/|../webpack/|g' "$REPO_ROOT/scripts/build.ts" 2>/dev/null || \
  sed -i '' 's|../../../webpack/|../webpack/|g' "$REPO_ROOT/scripts/build.ts"
sed -i 's|../../../webpack/|../webpack/|g' "$REPO_ROOT/scripts/start.ts" 2>/dev/null || \
  sed -i '' 's|../../../webpack/|../webpack/|g' "$REPO_ROOT/scripts/start.ts"

echo "Patching webpack getWorkspaces()..."
python3 - "$REPO_ROOT/webpack/config/webpack.config.ts" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

# Replace execSync import with path import
content = re.sub(r"import \{ execSync \} from 'child_process'\n", "import path from 'path'\n", content)

# Replace getWorkspaces function body
old = r"function getWorkspaces\(\) \{.*?\}"
new = """function getWorkspaces() {
  return [path.resolve(process.cwd(), 'node_modules/@jbrowse')]
}"""
content = re.sub(old, new, content, flags=re.DOTALL)

with open(path, 'w') as f:
    f.write(content)
print("webpack config patched.")
PYEOF

# Restore upgrade script (it was overwritten by the src copy above)
cp /tmp/upgrade.sh.bak "$REPO_ROOT/scripts/upgrade.sh" 2>/dev/null || true

echo ""
echo "Done. Version $VERSION applied."
echo ""
echo "IMPORTANT: Manually re-apply any custom modifications (e.g. postMessage listener in src/components/JBrowse.tsx)."
echo "Run: npm install && npm run build"
