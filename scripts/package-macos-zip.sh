#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-aarch64-apple-darwin}"

if [[ "$TARGET" != "aarch64-apple-darwin" && "$TARGET" != "x86_64-apple-darwin" && "$TARGET" != "universal-apple-darwin" ]]; then
  echo "Unsupported target: $TARGET"
  echo "Usage: scripts/package-macos-zip.sh [aarch64-apple-darwin|x86_64-apple-darwin|universal-apple-darwin]"
  exit 1
fi

APP_SRC="$ROOT_DIR/target/$TARGET/release/bundle/macos/Clash Verge.app"
if [[ ! -d "$APP_SRC" ]]; then
  echo "App not found: $APP_SRC"
  exit 1
fi

VERSION="$(node -p "require('./package.json').version")"
case "$TARGET" in
  aarch64-apple-darwin) ARCH_NAME="aarch64" ;;
  x86_64-apple-darwin) ARCH_NAME="x64" ;;
  universal-apple-darwin) ARCH_NAME="universal" ;;
esac

OUT_DIR="$ROOT_DIR/dist/zip-checksum"
TMP_DIR="$(mktemp -d /tmp/clash_verge_pkg.XXXXXX)"
APP_TMP="$TMP_DIR/Clash Verge.app"
ZIP_NAME="Clash_Verge_${VERSION}_macos_${ARCH_NAME}.zip"
ZIP_PATH="$OUT_DIR/$ZIP_NAME"

mkdir -p "$OUT_DIR"
cp -R "$APP_SRC" "$APP_TMP"

# Clear quarantine-like attributes and re-sign to avoid "app is damaged" style failures.
xattr -cr "$APP_TMP" || true
codesign --remove-signature "$APP_TMP" >/dev/null 2>&1 || true
codesign --force --deep --sign - "$APP_TMP"
codesign --verify --deep --strict --verbose=2 "$APP_TMP"

rm -f "$ZIP_PATH" "$ZIP_PATH.sha256"
ditto -c -k --sequesterRsrc --keepParent "$APP_TMP" "$ZIP_PATH"

SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
printf "%s  %s\n" "$SHA256" "$ZIP_NAME" > "$ZIP_PATH.sha256"

(
  cd "$OUT_DIR"
  rm -f SHA256SUMS.txt
  for f in *.zip; do
    [[ -f "$f" ]] || continue
    shasum -a 256 "$f" >> SHA256SUMS.txt
  done
)

rm -rf "$TMP_DIR"
echo "Done: $ZIP_PATH"
echo "Done: $ZIP_PATH.sha256"
