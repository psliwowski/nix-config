#!/usr/bin/env bash
set -euo pipefail

statix check .
deadnix --fail .
markdownlint-cli2 '**/*.{md,markdown}'

# Include new files while honoring Git ignore rules; preserve spaces in paths.
while IFS= read -r -d '' file; do
  shellcheck "$file"
done < <(git ls-files --cached --others --exclude-standard -z -- '*.sh')

for file in justfile modules/just/justfile modules/just/*.just; do
  just -f "$file" --dump >/dev/null
done
