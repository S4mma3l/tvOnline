#!/usr/bin/env bash
# Builds a signed iOS IPA locally and uploads it to the GitHub release.
# Usage: ./scripts/release_ios.sh v1.0.3
set -e

TAG=${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.3")}
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
IPA_DIR="build/ios/ipa"
IPA="$IPA_DIR/tvOnline.ipa"

echo "▶ Construyendo iOS IPA firmado para $TAG..."

# flutter build ipa handles archive + export in one step (Xcode auto-signs)
flutter build ipa \
  --dart-define-from-file=env.json \
  --export-options-plist=ExportOptions.plist \
  --release

# Locate the exported IPA (Xcode may name it after the app)
EXPORTED=$(find "$IPA_DIR" -name "*.ipa" | head -1)
if [ -z "$EXPORTED" ]; then
  echo "✗ No se encontró un .ipa en $IPA_DIR" >&2
  exit 1
fi
if [ "$EXPORTED" != "$IPA" ]; then
  mv "$EXPORTED" "$IPA"
fi

echo "▶ Subiendo $IPA al release $TAG en $REPO..."

# Create release if it doesn't exist yet
gh release view "$TAG" --repo "$REPO" > /dev/null 2>&1 || \
  gh release create "$TAG" --repo "$REPO" --title "tvOnline $TAG" --draft

gh release upload "$TAG" "$IPA" \
  --repo "$REPO" \
  --clobber

echo "✓ tvOnline.ipa subido al release $TAG"
echo "  https://github.com/$REPO/releases/tag/$TAG"
