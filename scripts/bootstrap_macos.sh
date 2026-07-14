#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_VERSION="4.7-stable"
GODOT_VERSION_EXPECTED="4.7.stable"
GODOT_RELEASE_BASE="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}"
GODOT_ARCHIVE="Godot_v${GODOT_VERSION}_macos.universal.zip"
GODOT_ARCHIVE_URL="${GODOT_RELEASE_BASE}/${GODOT_ARCHIVE}"
GODOT_CHECKSUMS_URL="${GODOT_RELEASE_BASE}/SHA512-SUMS.txt"
GODOT_DIR="${ROOT_DIR}/.tools/godot/${GODOT_VERSION}"
GODOT_BIN="${GODOT_DIR}/Godot.app/Contents/MacOS/Godot"
EXPORT_TEMPLATES_ARCHIVE="Godot_v${GODOT_VERSION}_export_templates.tpz"
EXPORT_TEMPLATES_URL="${GODOT_RELEASE_BASE}/${EXPORT_TEMPLATES_ARCHIVE}"
GUT_VERSION="9.7.1"
GUT_ARCHIVE_URL="https://github.com/bitwes/Gut/archive/refs/tags/v${GUT_VERSION}.zip"
GDTOOLKIT_VERSION="4.5.0"

require_command() {
  local name="$1"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "Missing required command: ${name}" >&2
    exit 1
  fi
}

ensure_homebrew_package() {
  local command_name="$1"
  local package_name="$2"

  if command -v "${command_name}" >/dev/null 2>&1; then
    return
  fi

  require_command brew
  echo "Installing ${package_name} with Homebrew..."
  brew install "${package_name}"
}

download() {
  local url="$1"
  local destination="$2"

  mkdir -p "$(dirname "${destination}")"
  curl --fail --location --show-error --progress-bar "${url}" --output "${destination}"
}

verify_sha512() {
  local checksums_file="$1"
  local artifact_file="$2"
  local artifact_name
  local expected
  local actual

  artifact_name="$(basename "${artifact_file}")"
  expected="$(awk -v name="${artifact_name}" '$2 == name { print $1 }' "${checksums_file}")"

  if [[ -z "${expected}" ]]; then
    echo "Checksum not found for ${artifact_name}" >&2
    exit 1
  fi

  actual="$(shasum -a 512 "${artifact_file}" | awk '{ print $1 }')"

  if [[ "${actual}" != "${expected}" ]]; then
    echo "Checksum mismatch for ${artifact_name}" >&2
    exit 1
  fi
}

install_godot() {
  local archive_path="${GODOT_DIR}/${GODOT_ARCHIVE}"
  local checksums_path="${GODOT_DIR}/SHA512-SUMS.txt"

  if [[ -x "${GODOT_BIN}" ]]; then
    echo "Godot already installed at ${GODOT_BIN}"
  else
    echo "Downloading Godot ${GODOT_VERSION}..."
    mkdir -p "${GODOT_DIR}"
    download "${GODOT_ARCHIVE_URL}" "${archive_path}"
    download "${GODOT_CHECKSUMS_URL}" "${checksums_path}"
    verify_sha512 "${checksums_path}" "${archive_path}"
    unzip -q "${archive_path}" -d "${GODOT_DIR}"

    if command -v xattr >/dev/null 2>&1; then
      xattr -dr com.apple.quarantine "${GODOT_DIR}/Godot.app" 2>/dev/null || true
    fi
  fi

  local version_output
  version_output="$("${GODOT_BIN}" --version)"
  echo "Godot version: ${version_output}"

  if [[ "${version_output}" != *"${GODOT_VERSION_EXPECTED}"* ]]; then
    echo "Unexpected Godot version. Expected ${GODOT_VERSION_EXPECTED}." >&2
    exit 1
  fi
}

install_gut() {
  local addons_dir="${ROOT_DIR}/addons"
  local gut_dir="${addons_dir}/gut"
  local tmp_dir="${ROOT_DIR}/.tools/tmp/gut-${GUT_VERSION}"
  local archive_path="${tmp_dir}/gut.zip"

  if [[ -f "${gut_dir}/plugin.cfg" && -f "${gut_dir}/gut_cmdln.gd" ]]; then
    echo "GUT already installed at ${gut_dir}"
    return
  fi

  echo "Installing GUT ${GUT_VERSION}..."
  rm -rf "${tmp_dir}"
  mkdir -p "${tmp_dir}" "${addons_dir}"
  download "${GUT_ARCHIVE_URL}" "${archive_path}"
  unzip -q "${archive_path}" -d "${tmp_dir}"
  rm -rf "${gut_dir}"
  cp -R "${tmp_dir}/Gut-${GUT_VERSION}/addons/gut" "${gut_dir}"
}

install_gdtoolkit() {
  ensure_homebrew_package pipx pipx
  local pipx_bin
  pipx_bin="$(command -v pipx)"

  if "${pipx_bin}" list 2>/dev/null | grep -q "package gdtoolkit ${GDTOOLKIT_VERSION}"; then
    echo "gdtoolkit ${GDTOOLKIT_VERSION} already installed"
  else
    echo "Installing gdtoolkit ${GDTOOLKIT_VERSION} with pipx..."
    "${pipx_bin}" install --force "gdtoolkit==${GDTOOLKIT_VERSION}"
  fi
}

install_just() {
  ensure_homebrew_package just just
}

install_git_lfs() {
  ensure_homebrew_package git-lfs git-lfs

  if [[ -d "${ROOT_DIR}/.git" ]]; then
    git -C "${ROOT_DIR}" lfs install --local
  else
    git lfs install
  fi
}

maybe_cache_export_templates() {
  if [[ "${INSTALL_EXPORT_TEMPLATES:-0}" != "1" ]]; then
    echo "Export templates are not installed by default."
    echo "Set INSTALL_EXPORT_TEMPLATES=1 to cache ${EXPORT_TEMPLATES_ARCHIVE} in .tools."
    return
  fi

  local archive_path="${GODOT_DIR}/${EXPORT_TEMPLATES_ARCHIVE}"
  local checksums_path="${GODOT_DIR}/SHA512-SUMS.txt"

  echo "Caching export templates..."
  download "${EXPORT_TEMPLATES_URL}" "${archive_path}"
  [[ -f "${checksums_path}" ]] || download "${GODOT_CHECKSUMS_URL}" "${checksums_path}"
  verify_sha512 "${checksums_path}" "${archive_path}"
}

main() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This bootstrap script is intended for macOS." >&2
    exit 1
  fi

  require_command curl
  require_command unzip
  require_command shasum
  require_command git

  install_git_lfs
  install_just
  install_godot
  install_gut
  install_gdtoolkit
  maybe_cache_export_templates

  echo "Bootstrap complete."
}

main "$@"
