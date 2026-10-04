#!/usr/bin/env bash
# cursor-skills-vault — install shared Cursor skills from a private vault.
#
# Usage:
#   ./bootstrap.sh                 # same as: setup
#   ./bootstrap.sh setup           # clone or seed the vault, install skills
#   ./bootstrap.sh update          # pull the engine and vault, reinstall
#   ./bootstrap.sh status          # show the vault and installed skills
#   ./bootstrap.sh install [name]  # install vault skills into ~/.cursor/
#   ./bootstrap.sh import <name> <source-dir>
#
# Config: config.local.env (see config.example.env)
set -euo pipefail

BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${BOOTSTRAP_ROOT}/scripts/lib.sh"

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

vault_has_commit() {
  git -C "${CURSOR_SKILLS_VAULT}" rev-parse --verify HEAD >/dev/null 2>&1
}

vault_is_dirty() {
  [[ -n "$(git -C "${CURSOR_SKILLS_VAULT}" status --porcelain)" ]]
}

copy_template() {
  local src="${ENGINE_ROOT}/vault-template"
  [[ -d "${src}" ]] || die "missing vault template: ${src}"
  cp -R "${src}/." "${CURSOR_SKILLS_VAULT}/"
  echo "Copied vault template into ${CURSOR_SKILLS_VAULT}"
}

cmd_setup() {
  need_cmd git
  need_cmd python3
  load_config

  if [[ -z "${CURSOR_SKILLS_VAULT:-}" ]]; then
    die "CURSOR_SKILLS_VAULT is unset. Copy config.example.env to config.local.env and set it."
  fi

  if [[ ! -e "${CURSOR_SKILLS_VAULT}" ]]; then
    [[ -n "${CURSOR_SKILLS_VAULT_URL:-}" ]] || die "CURSOR_SKILLS_VAULT does not exist and CURSOR_SKILLS_VAULT_URL is unset."
    info "Cloning vault"
    git clone "${CURSOR_SKILLS_VAULT_URL}" "${CURSOR_SKILLS_VAULT}"
  fi

  [[ -d "${CURSOR_SKILLS_VAULT}/.git" ]] || die "CURSOR_SKILLS_VAULT is not a git repo: ${CURSOR_SKILLS_VAULT}"
  require_vault

  if ! vault_has_commit; then
    if vault_is_dirty; then
      die "vault directory is not an empty git repo: ${CURSOR_SKILLS_VAULT}"
    fi
    copy_template
    "${ENGINE_ROOT}/scripts/sync-vault.sh" "Initial cursor-skills vault."
  elif [[ -d "${CURSOR_SKILLS_VAULT}/skills" ]]; then
    info "Vault already has skills/"
    if git -C "${CURSOR_SKILLS_VAULT}" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
      if ! git -C "${CURSOR_SKILLS_VAULT}" pull --ff-only; then
        die "vault cannot fast-forward: ${CURSOR_SKILLS_VAULT}"
      fi
    else
      echo "remote is missing; left vault local."
    fi
  else
    die "vault is not empty and has no skills directory: ${CURSOR_SKILLS_VAULT}"
  fi

  "${ENGINE_ROOT}/scripts/install-skills.sh"
  "${ENGINE_ROOT}/scripts/install-engine-skill.sh"
  ok "Setup complete"
  echo "Start a new Cursor agent so the skill loads."
}

cmd_update() {
  need_cmd git
  need_cmd python3
  load_config
  require_vault

  if [[ -d "${ENGINE_ROOT}/.git" ]]; then
    info "Pulling engine"
    if git -C "${ENGINE_ROOT}" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
      if ! git -C "${ENGINE_ROOT}" pull --ff-only; then
        die "engine cannot fast-forward: ${ENGINE_ROOT}"
      fi
    else
      echo "remote is missing; left engine local."
    fi
  fi
  load_config
  require_vault

  info "Pulling vault"
  if git -C "${CURSOR_SKILLS_VAULT}" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    if ! git -C "${CURSOR_SKILLS_VAULT}" pull --ff-only; then
      die "vault cannot fast-forward: ${CURSOR_SKILLS_VAULT}"
    fi
  else
    echo "remote is missing; left vault local."
  fi

  "${ENGINE_ROOT}/scripts/install-skills.sh"
  "${ENGINE_ROOT}/scripts/install-engine-skill.sh"
  ok "Update complete"
}

cmd_status() {
  load_config
  echo "cursor-skills-vault status"
  echo "engine:    ${CURSOR_SKILLS_ENGINE:-${ENGINE_ROOT}}"
  echo "vault:     ${CURSOR_SKILLS_VAULT:-"(unset)"}"
  echo "transport: ${CURSOR_SKILLS_GIT_TRANSPORT}"
  if [[ -f "${HOME}/.cursor/skills/cursor-skills-vault/SKILL.md" ]]; then
    echo "engine skill: installed"
  else
    echo "engine skill: missing"
  fi
  if [[ -n "${CURSOR_SKILLS_VAULT:-}" && -d "${CURSOR_SKILLS_VAULT}/.git" ]]; then
    "${ENGINE_ROOT}/scripts/list-skills.sh"
  fi
}

load_config

cmd="${1:-setup}"
shift || true

case "${cmd}" in
  -h|--help|help) usage ;;
  setup) cmd_setup "$@" ;;
  update) cmd_update "$@" ;;
  status) cmd_status "$@" ;;
  install)
    load_config
    "${ENGINE_ROOT}/scripts/install-skills.sh" "$@"
    ;;
  import)
    load_config
    [[ $# -eq 2 ]] || die "usage: $0 import <name> <source-directory>"
    "${ENGINE_ROOT}/scripts/import-skill.sh" "$1" "$2"
    ;;
  *)
    die "unknown command: ${cmd} (try: setup|update|status|install|import)"
    ;;
esac
