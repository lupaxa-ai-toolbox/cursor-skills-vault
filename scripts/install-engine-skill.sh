#!/usr/bin/env bash
# Install the cursor-skills-vault skill and rule into ~/.cursor/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib.sh"

SKILL_SRC="${ENGINE_ROOT}/skills/cursor-skills-vault"
RULE_SRC="${ENGINE_ROOT}/rules/cursor-skills-vault.mdc"
SKILL_DEST="${HOME}/.cursor/skills/cursor-skills-vault"
RULE_DEST="${HOME}/.cursor/rules/cursor-skills-vault.mdc"

[[ -f "${SKILL_SRC}/SKILL.md" ]] || die "missing ${SKILL_SRC}/SKILL.md"
[[ -f "${RULE_SRC}" ]] || die "missing ${RULE_SRC}"

rm -rf "${SKILL_DEST}"
mkdir -p "${SKILL_DEST}" "${HOME}/.cursor/rules"
cp -R "${SKILL_SRC}/." "${SKILL_DEST}/"
cp "${RULE_SRC}" "${RULE_DEST}"

echo "Installed skill -> ${SKILL_DEST}"
echo "Installed rule -> ${RULE_DEST}"
