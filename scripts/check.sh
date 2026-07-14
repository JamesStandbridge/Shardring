#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_command() {
  local name="$1"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "Missing command: ${name}. Run scripts/bootstrap_macos.sh first." >&2
    exit 1
  fi
}

main() {
  require_command gdformat
  require_command gdlint
  require_command gdparse

  local gd_files=()
  while IFS= read -r -d '' file; do
    gd_files+=("${file}")
  done < <(find "${ROOT_DIR}/src" "${ROOT_DIR}/tests" -name '*.gd' -print0)

  if ((${#gd_files[@]} > 0)); then
    gdformat --check "${gd_files[@]}"
    gdlint "${gd_files[@]}"

    local file
    for file in "${gd_files[@]}"; do
      gdparse "${file}" >/dev/null
    done
  fi

  "${ROOT_DIR}/scripts/run_tests.sh"
}

main "$@"

