#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-${ROOT_DIR}/.tools/godot/4.7-stable/Godot.app/Contents/MacOS/Godot}"

if [[ ! -x "${GODOT_BIN}" ]]; then
  echo "Godot binary not found at ${GODOT_BIN}. Run scripts/bootstrap_macos.sh first." >&2
  exit 1
fi

if [[ ! -f "${ROOT_DIR}/addons/gut/gut_cmdln.gd" ]]; then
  echo "GUT is not installed. Run scripts/bootstrap_macos.sh first." >&2
  exit 1
fi

mkdir -p "${ROOT_DIR}/reports/gut"

"${GODOT_BIN}" --headless --import --path "${ROOT_DIR}"

exec "${GODOT_BIN}" --headless -d -s --path "${ROOT_DIR}" addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit \
  -gdir=res://tests/integration \
  -ginclude_subdirs \
  -gprefix=test_ \
  -gsuffix=.gd \
  -gjunit_xml_file=res://reports/gut/junit.xml \
  -gexit
