#!/usr/bin/env bash
# Encrypt each plaintext doc in sources/ into an opaque-ID folder under docs/,
# then generate and encrypt the catalog. Passwords and the friendly-name mapping
# live in passwords.env (gitignored). The public repo never contains plaintext,
# topic names, or the mapping.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f passwords.env ]]; then
  echo "ERROR: passwords.env not found." >&2
  echo "Copy passwords.env.example to passwords.env, fill it in from 1Password, then retry." >&2
  exit 1
fi
# shellcheck disable=SC1091
source passwords.env

BIN="./node_modules/.bin/staticrypt"

# Shared StatiCrypt options. --remember false hides the "remember me" box (no
# localStorage). --config false keeps no salt file. Title is generic on purpose.
COMMON=(
  --remember false
  --config false
  --short
  --template "template/password-page.html"
  --template-title "Paays · Internal Document"
  --template-instructions "Paays internal document. Enter the access password to continue."
  --template-placeholder "Access password"
  --template-button "Unlock"
  --template-color-primary "#1d4ed8"
  --template-color-secondary "#0b1f3a"
)

mkdir -p docs
items=""
for entry in "${DOCS[@]}"; do
  IFS='|' read -r id sub name desc pw <<< "$entry"
  src="sources/$sub/index.html"
  if [[ -z "$id" || -z "$pw" ]]; then echo "SKIP  $sub (missing id or password)"; continue; fi
  if [[ ! -f "$src" ]]; then echo "SKIP  $sub (missing $src)"; continue; fi
  "$BIN" "$src" -p "$pw" -d "docs/$id" "${COMMON[@]}" >/dev/null
  echo "OK    $sub -> docs/$id/index.html"
  items+="      <li><a class=\"doc\" href=\"$id/\"><p class=\"doc-title\">$name</p><p class=\"doc-desc\">$desc</p></a></li>"$'\n'
done

# Generate the catalog from the template, inject the doc list, encrypt to docs/index.html.
if [[ -n "${PW_CATALOG:-}" && -f template/catalog.html ]]; then
  tmpd="$(mktemp -d)"
  template="$(<template/catalog.html)"
  printf '%s' "${template/<!--DOCS-->/$items}" > "$tmpd/index.html"
  "$BIN" "$tmpd/index.html" -p "$PW_CATALOG" -d docs "${COMMON[@]}" >/dev/null
  rm -rf "$tmpd"
  echo "OK    catalog -> docs/index.html"
else
  echo "SKIP  catalog (need PW_CATALOG and template/catalog.html)"
fi

echo "Build complete. Served files are in docs/ (opaque IDs)."
