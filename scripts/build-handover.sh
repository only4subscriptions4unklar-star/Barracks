#!/usr/bin/env bash
#
# Builds barracks-handover.zip — the client deliverable.
#
# The archive is a build artifact and is deliberately not committed: every file
# in it is already tracked in this repository, so storing the binary would only
# bloat history. Run this to regenerate it.
#
# Usage:  ./scripts/build-handover.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/barracks-handover.zip"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cd "$REPO_ROOT"

mkdir -p "$STAGE/website" "$STAGE/platform" "$STAGE/docs"

# 1. The live-ready static storefront (cp -a preserves the hidden .htaccess).
cp -a deploy/. "$STAGE/website/"

# 2. Platform source, minus dependencies, build output and any local secrets.
tar --exclude=node_modules \
    --exclude=.next \
    --exclude='.env*.local' \
    --exclude=next-env.d.ts \
    --exclude=tsconfig.tsbuildinfo \
    --exclude='*.whl' \
    --exclude=CLAUDE.md \
    -cf - -C platform . | tar -xf - -C "$STAGE/platform"

# Brand assets the Next.js app will serve, replacing the framework's boilerplate.
rm -f "$STAGE/platform/public/"{file,globe,next,vercel,window}.svg
mkdir -p "$STAGE/platform/public"
cp deploy/favicon.svg deploy/og-image.png "$STAGE/platform/public/"

# 3. Documentation.
cp AUDIT.md REDESIGN.md "$STAGE/docs/"

# 4. The orientation page that explains what is deployable and what is not.
cp docs/START-HERE.md "$STAGE/START-HERE.md"

find "$STAGE" -name '.DS_Store' -delete

rm -f "$OUT"
( cd "$STAGE" && zip -r -q -X "$OUT" . )

# Fail loudly rather than shipping dependencies or secrets to a client.
if unzip -Z1 "$OUT" | grep -qE 'node_modules|\.next/|\.env\.local|\.whl$'; then
  echo "ERROR: archive contains files that must not be distributed" >&2
  exit 1
fi

echo "Built $OUT"
unzip -Z1 "$OUT" | wc -l | xargs echo "  files:"
du -h "$OUT" | cut -f1 | xargs echo "  size: "
