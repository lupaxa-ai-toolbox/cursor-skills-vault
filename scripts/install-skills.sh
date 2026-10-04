#!/usr/bin/env bash
# Install skills from the private vault into ~/.cursor/skills/.
#
# Usage:
#   ./scripts/install-skills.sh           # every skill in the vault
#   ./scripts/install-skills.sh <name>    # one skill
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib.sh"
load_config
require_vault

SKILLS_DIR="${CURSOR_SKILLS_VAULT}/skills"
DEST_ROOT="${HOME}/.cursor/skills"
RULES_DEST="${HOME}/.cursor/rules"

[[ -d "${SKILLS_DIR}" ]] || die "vault has no skills directory: ${SKILLS_DIR}"

install_one() {
  local name="$1"
  local src="${SKILLS_DIR}/${name}"
  local dest="${DEST_ROOT}/${name}"

  [[ -f "${src}/SKILL.md" ]] || die "missing ${src}/SKILL.md"
  mkdir -p "${DEST_ROOT}"
  rm -rf "${dest}"
  mkdir -p "${dest}"
  cp -R "${src}/." "${dest}/"
  echo "Installed ${name} -> ${dest}"

  if [[ -d "${src}/rules" ]]; then
    mkdir -p "${RULES_DEST}"
    local rule
    shopt -s nullglob
    for rule in "${src}/rules/"*.mdc; do
      cp "${rule}" "${RULES_DEST}/$(basename "${rule}")"
      echo "Installed rule $(basename "${rule}") -> ${RULES_DEST}/"
    done
    shopt -u nullglob
  fi
}

if [[ $# -ge 1 ]]; then
  for name in "$@"; do
    safe_skill_name "${name}"
    install_one "${name}"
  done
else
  shopt -s nullglob
  found=0
  for src in "${SKILLS_DIR}"/*/; do
    name="$(basename "${src}")"
    [[ -f "${src}/SKILL.md" ]] || continue
    install_one "${name}"
    found=1
  done
  shopt -u nullglob
  if [[ "${found}" -eq 0 ]]; then
    echo "No skills in the vault."
  fi
fi
