#!/usr/bin/env bash
# Local checks for cursor-skills-vault. Uses temporary git repositories only.
set -euo pipefail

ENGINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cursor-skills-vault.XXXXXX")"
HOME_DIR="${ROOT}/home"
export HOME="${HOME_DIR}"
export GIT_AUTHOR_NAME="Vault Test"
export GIT_AUTHOR_EMAIL="vault-test@example.com"
export GIT_COMMITTER_NAME="Vault Test"
export GIT_COMMITTER_EMAIL="vault-test@example.com"

PASS=0
FAIL=0

cleanup() {
  rm -rf "${ROOT}"
}
trap cleanup EXIT

say() { printf '%s\n' "$*"; }
pass() { PASS=$((PASS + 1)); say "PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); say "FAIL: $1"; }

init_repo() {
  mkdir -p "$1"
  git -C "$1" init -b master >/dev/null
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -m "$2" >/dev/null
}

new_vault() {
  init_repo "$1"
  cp -R "${ENGINE}/vault-template/." "$1/"
  commit_all "$1" "Initial cursor-skills vault."
}

write_skill() {
  local dir="$1"
  local name="$2"
  mkdir -p "${dir}/rules"
  cat > "${dir}/SKILL.md" <<EOF
---
name: ${name}
description: Test skill ${name}
---

# ${name}
EOF
  echo "rule" > "${dir}/rules/${name}.mdc"
}

run_setup() {
  env CURSOR_SKILLS_VAULT="$1" "${ENGINE}/bootstrap.sh" setup
}

setup_empty() {
  local vault="${ROOT}/setup-empty"
  init_repo "${vault}"
  run_setup "${vault}" >/dev/null
  [[ -d "${vault}/skills" ]] || { fail "setup empty: missing skills/"; return; }
  git -C "${vault}" rev-parse --verify HEAD >/dev/null || { fail "setup empty: no commit"; return; }
  [[ -f "${HOME_DIR}/.cursor/skills/cursor-skills-vault/SKILL.md" ]] || { fail "setup empty: engine skill"; return; }
  pass "setup copies the template into an empty vault"
}

setup_keeps_skills() {
  local vault="${ROOT}/setup-keep"
  new_vault "${vault}"
  echo "KEEP-ME" > "${vault}/skills/KEEP-ME"
  commit_all "${vault}" "Marker"
  run_setup "${vault}" >/dev/null
  grep -q 'KEEP-ME' "${vault}/skills/KEEP-ME" || { fail "setup keep: marker missing"; return; }
  pass "setup leaves an existing skills vault alone"
}

setup_refuses_unrelated() {
  local vault="${ROOT}/setup-unrelated"
  mkdir -p "${vault}"
  echo notes > "${vault}/notes.txt"
  if run_setup "${vault}" >/dev/null 2>&1; then
    fail "setup unrelated: expected failure"
    return
  fi
  [[ -f "${vault}/notes.txt" ]] || { fail "setup unrelated: file removed"; return; }
  pass "setup refuses an unrelated non-empty directory"
}

setup_refuses_git_without_skills() {
  local vault="${ROOT}/setup-noskills"
  init_repo "${vault}"
  echo notes > "${vault}/notes.txt"
  commit_all "${vault}" "Notes"
  if run_setup "${vault}" >/dev/null 2>&1; then
    fail "setup no skills: expected failure"
    return
  fi
  [[ -f "${vault}/notes.txt" ]] || { fail "setup no skills: file removed"; return; }
  pass "setup refuses a git repo with no skills directory"
}

import_and_install() {
  local vault="${ROOT}/import-vault"
  local source="${ROOT}/import-src"
  new_vault "${vault}"
  write_skill "${source}" "demo-skill"
  env CURSOR_SKILLS_VAULT="${vault}" "${ENGINE}/scripts/import-skill.sh" demo-skill "${source}" >/dev/null
  [[ -f "${vault}/skills/demo-skill/SKILL.md" ]] || { fail "import: missing skill"; return; }
  env HOME="${HOME_DIR}" CURSOR_SKILLS_VAULT="${vault}" "${ENGINE}/scripts/install-skills.sh" demo-skill >/dev/null
  [[ -f "${HOME_DIR}/.cursor/skills/demo-skill/SKILL.md" ]] || { fail "install: skill"; return; }
  [[ -f "${HOME_DIR}/.cursor/rules/demo-skill.mdc" ]] || { fail "install: rule"; return; }
  pass "import stores a skill and install copies the skill and rule"
}

import_refuses_overwrite() {
  local vault="${ROOT}/over-vault"
  local source="${ROOT}/over-src"
  new_vault "${vault}"
  mkdir -p "${vault}/skills/demo-skill"
  echo keep > "${vault}/skills/demo-skill/keep.txt"
  write_skill "${source}" "demo-skill"
  if env CURSOR_SKILLS_VAULT="${vault}" "${ENGINE}/scripts/import-skill.sh" demo-skill "${source}" >/dev/null 2>&1; then
    fail "overwrite: expected failure"
    return
  fi
  [[ -f "${vault}/skills/demo-skill/keep.txt" ]] || { fail "overwrite: vault file lost"; return; }
  pass "import leaves an existing skill untouched"
}

import_unsafe() {
  local vault="${ROOT}/unsafe-vault"
  local source="${ROOT}/unsafe-src"
  new_vault "${vault}"
  write_skill "${source}" "bad-skill"
  if env CURSOR_SKILLS_VAULT="${vault}" "${ENGINE}/scripts/import-skill.sh" "bad skill" "${source}" >/dev/null 2>&1; then
    fail "unsafe: expected failure"
    return
  fi
  pass "unsafe skill name exits with an error"
}

sync_ignores_local() {
  local vault="${ROOT}/sync-vault"
  local source="${ROOT}/sync-src"
  new_vault "${vault}"
  write_skill "${source}" "synced-skill"
  env CURSOR_SKILLS_VAULT="${vault}" "${ENGINE}/scripts/import-skill.sh" synced-skill "${source}" >/dev/null
  echo "secret" > "${vault}/local.env"
  local out
  out="$(env CURSOR_SKILLS_VAULT="${vault}" "${ENGINE}/scripts/sync-vault.sh")"
  printf '%s\n' "${out}" | grep -q 'remote is missing' || { fail "sync: missing remote message"; return; }
  if git -C "${vault}" ls-files --error-unmatch local.env >/dev/null 2>&1; then
    fail "sync: local.env was staged"
    return
  fi
  git -C "${vault}" ls-files --error-unmatch skills/synced-skill/SKILL.md >/dev/null || { fail "sync: skill not committed"; return; }
  pass "vault commit stores the skill and skips local.env"
}

update_refuses_diverge() {
  local base="${ROOT}/ff-base"
  local vault="${ROOT}/ff-vault"
  new_vault "${base}"
  git clone "${base}" "${vault}" >/dev/null
  echo left >> "${base}/README.md"
  commit_all "${base}" "Left"
  echo right >> "${vault}/README.md"
  commit_all "${vault}" "Right"
  if env CURSOR_SKILLS_VAULT="${vault}" "${ENGINE}/bootstrap.sh" update >/dev/null 2>&1; then
    fail "update: expected fast-forward failure"
    return
  fi
  pass "update stops when the vault cannot fast-forward"
}

setup_empty
setup_keeps_skills
setup_refuses_unrelated
setup_refuses_git_without_skills
import_and_install
import_refuses_overwrite
import_unsafe
sync_ignores_local
update_refuses_diverge

say
say "Passed: ${PASS}  Failed: ${FAIL}"
[[ "${FAIL}" -eq 0 ]]
