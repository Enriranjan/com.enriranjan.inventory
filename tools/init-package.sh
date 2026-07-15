#!/usr/bin/env bash
# init-package.sh
#
# One-shot initializer for a package generated from unity-package-template.
# Replaces the __PACKAGE_ID__ / __PACKAGE_NAME__ / __DISPLAY_NAME__ /
# __DESCRIPTION__ tokens across the repo, renames the files that carry a
# token in their name, then deletes the tools/ folder (including itself).
#
# Usage:
#   tools/init-package.sh <package-id> <PackageName> "<Display Name>" "<Description>" [-y|--yes]
#
# Any argument omitted is prompted for interactively.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ASSUME_YES=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done

PACKAGE_ID="${ARGS[0]:-}"
PACKAGE_NAME="${ARGS[1]:-}"
DISPLAY_NAME="${ARGS[2]:-}"
DESCRIPTION="${ARGS[3]:-}"

if [ -z "$PACKAGE_ID" ]; then
  read -rp "package-id (lowercase, no spaces, e.g. 'mypackage'): " PACKAGE_ID
fi
if [ -z "$PACKAGE_NAME" ]; then
  read -rp "PackageName (PascalCase, e.g. 'MyPackage'): " PACKAGE_NAME
fi
if [ -z "$DISPLAY_NAME" ]; then
  read -rp "Display Name (e.g. 'My Package'): " DISPLAY_NAME
fi
if [ -z "$DESCRIPTION" ]; then
  read -rp "Short description: " DESCRIPTION
fi

if [[ ! "$PACKAGE_ID" =~ ^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*)*$ ]]; then
echo "Error: package-id must be lowercase letters/digits/hyphens, with optional dot-separated segments, each starting with a letter (got '$PACKAGE_ID')." >&2  exit 1
fi
if [[ ! "$PACKAGE_NAME" =~ ^[A-Z][A-Za-z0-9]*(\.[A-Z][A-Za-z0-9]*)*$ ]]; then
  echo "Error: PackageName must be PascalCase, starting with an uppercase letter (got '$PACKAGE_NAME')." >&2
  exit 1
fi
if [ -z "$DISPLAY_NAME" ]; then
  echo "Error: Display Name cannot be empty." >&2
  exit 1
fi
if [ -z "$DESCRIPTION" ]; then
  echo "Error: Description cannot be empty." >&2
  exit 1
fi

echo ""
echo "About to initialize:"
echo "  package id    : com.enriranjan.$PACKAGE_ID"
echo "  PackageName   : $PACKAGE_NAME"
echo "  Display Name  : $DISPLAY_NAME"
echo "  Description   : $DESCRIPTION"
echo "  Repo root     : $ROOT_DIR"
echo ""
echo "This will rewrite files under the repo root and permanently delete tools/."

if [ "$ASSUME_YES" -ne 1 ]; then
  read -rp "Continue? [y/N] " CONFIRM
  case "$CONFIRM" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

replace_tokens_in_file() {
  local file="$1"
  local content
  content="$(cat "$file")"
  local updated="${content//__PACKAGE_ID__/$PACKAGE_ID}"
  updated="${updated//__PACKAGE_NAME__/$PACKAGE_NAME}"
  updated="${updated//__DISPLAY_NAME__/$DISPLAY_NAME}"
  updated="${updated//__DESCRIPTION__/$DESCRIPTION}"
  if [ "$updated" != "$content" ]; then
    printf '%s\n' "$updated" > "$file"
  fi
}

echo ""
echo "Replacing tokens in file contents..."
while IFS= read -r -d '' file; do
  replace_tokens_in_file "$file"
done < <(find "$ROOT_DIR" -type f -not -path "*/.git/*" -not -path "$SCRIPT_DIR/*" -print0)

echo "Renaming files with tokens in their name..."
while IFS= read -r -d '' file; do
  dir="$(dirname "$file")"
  base="$(basename "$file")"
  newbase="${base//__PACKAGE_ID__/$PACKAGE_ID}"
  newbase="${newbase//__PACKAGE_NAME__/$PACKAGE_NAME}"
  if [ "$newbase" != "$base" ]; then
    mv -- "$file" "$dir/$newbase"
    echo "  $base -> $newbase"
  fi
done < <(find "$ROOT_DIR" -type f -not -path "*/.git/*" -not -path "$SCRIPT_DIR/*" -print0)

echo "Removing tools/ (self-cleanup)..."
rm -rf -- "$SCRIPT_DIR"

cat <<EOF

Done. com.enriranjan.$PACKAGE_ID ("$DISPLAY_NAME") is ready.

Next steps:

1) Commit the result:
     git add -A
     git commit -m "chore: initialize $PACKAGE_NAME from unity-package-template"

2) Tag your first release (required for Git URL installs to pin a version):
     git tag v0.1.0
     git push origin main --tags

3) Install it in a Unity project:

   a) As a Git dependency (recommended for consumers), add to the
      project's Packages/manifest.json:
        "com.enriranjan.$PACKAGE_ID": "https://github.com/enriranjan/$PACKAGE_ID.git#v0.1.0"
      Bump the #v0.1.0 tag whenever you cut a new release.

   b) As an embedded package (recommended while developing the package
      itself), clone this repo directly into the target project's
      Packages/ folder:
        Packages/com.enriranjan.$PACKAGE_ID/
      Unity auto-detects any folder under Packages/ that contains a
      package.json as an embedded, editable package - no manifest.json
      entry needed.
EOF
