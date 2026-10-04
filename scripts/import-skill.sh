#!/usr/bin/env bash
# Copy one skill directory into the private vault.
#
# Usage:
#   ./scripts/import-skill.sh <name> <source-directory>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib.sh"
load_config
require_vault

[[ $# -eq 2 ]] || die "usage: $0 <name> <source-directory>"
NAME="$1"
SOURCE="$2"
safe_skill_name "${NAME}"
[[ -d "${SOURCE}" ]] || die "source directory does not exist: ${SOURCE}"
[[ -f "${SOURCE}/SKILL.md" ]] || die "source has no SKILL.md: ${SOURCE}"

DEST="${CURSOR_SKILLS_VAULT}/skills/${NAME}"
if [[ -d "${DEST}" ]]; then
  for item in "${DEST}"/* "${DEST}"/.[!.]* "${DEST}"/..?*; do
    if [[ -e "${item}" ]]; then
      die "vault skill already has files: ${DEST}"
    fi
  done
fi

mkdir -p "${DEST}"
cp -R "${SOURCE}/." "${DEST}/"
echo "Imported ${NAME} -> ${DEST}"
