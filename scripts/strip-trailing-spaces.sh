#!/usr/bin/env bash

set -euo pipefail

# Normalize chart files under charts/
# - Strip trailing whitespace from each line
# - Ensure EXACTLY one newline at end of file (remove trailing blank lines, then append one) 
# - Targets: *.yaml, *.yml, *.tpl, *.txt, Chart.yaml, values.yaml, .helmignore
# - Skips:   *.md (Markdown may intentionally use trailing spaces for hard line breaks)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${ROOT_DIR}/charts"

echo "[strip-trailing-spaces] scanning: ${TARGET_DIR}"

# Build find expression
find_expr=(
  -type f \( 
    -name "*.yaml" -o 
    -name "*.yml" -o 
    -name "*.tpl" -o 
    -name "*.txt" -o 
    -name "Chart.yaml" -o 
    -name "values.yaml" -o 
    -name ".helmignore" 
  \) ! -name "*.md"
)

mapfile -t files < <(find "${TARGET_DIR}" "${find_expr[@]}" | sort)

changed=0
for f in "${files[@]}"; do
  # Strip trailing whitespace in-place
  sed -i -E 's/[[:space:]]+$//' "$f"

  # Ensure EXACTLY one newline at EOF:
  # - Remove trailing blank lines
  # - Append a single newline
  tmp_file=$(mktemp)
  awk 'BEGIN{n=0} {lines[++n]=$0} END{while(n>0 && lines[n] ~ /^[[:space:]]*$/) n--; for(i=1;i<=n;i++) print lines[i]; print ""}' "$f" > "$tmp_file"
  # Replace content only if different to preserve timestamps when no change
  if ! cmp -s "$f" "$tmp_file"; then
    cat "$tmp_file" > "$f"
  fi
  rm -f "$tmp_file"

  # Detect if file changed (git-aware if repo, otherwise fallback)
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git diff --quiet -- "$f"; then
      echo "[fixed] $f"
      changed=$((changed+1))
    fi
  else
    echo "[processed] $f"
    changed=$((changed+1))
  fi
done

echo "[strip-trailing-spaces] files changed: ${changed}"
exit 0