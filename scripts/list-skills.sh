#!/usr/bin/env bash
# List skills in the private vault and whether this machine has them installed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib.sh"
load_config
require_vault

export CURSOR_SKILLS_VAULT
export CURSOR_SKILLS_HOME="${HOME}"

python3 - <<'PY'
import os
import re
from pathlib import Path

vault = Path(os.environ["CURSOR_SKILLS_VAULT"]) / "skills"
home = Path(os.environ["CURSOR_SKILLS_HOME"]) / ".cursor" / "skills"
print(f"{'Skill':<28} {'Installed':<10} Description")
if not vault.is_dir():
    raise SystemExit(0)
for skill in sorted(p for p in vault.iterdir() if p.is_dir() and (p / "SKILL.md").is_file()):
    text = (skill / "SKILL.md").read_text(encoding="utf-8")
    description = ""
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end > 0:
            block = text[3:end]
            match = re.search(r"^description:\s*>?-?\s*(.*)$", block, re.M)
            if match:
                description = match.group(1).strip().strip('"').strip("'")
    installed = "yes" if (home / skill.name / "SKILL.md").is_file() else "no"
    print(f"{skill.name:<28} {installed:<10} {description}")
PY
