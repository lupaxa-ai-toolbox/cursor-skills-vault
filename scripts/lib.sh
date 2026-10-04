#!/usr/bin/env bash
# Shared helpers for the cursor-skills-vault engine.
# shellcheck shell=bash

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_ROOT="$(cd "${_LIB_DIR}/.." && pwd)"

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }
ok() { echo "OK: $*"; }

load_config() {
  local config="${ENGINE_ROOT}/config.local.env"
  local vault url engine transport
  vault="${CURSOR_SKILLS_VAULT:-}"
  url="${CURSOR_SKILLS_VAULT_URL:-}"
  engine="${CURSOR_SKILLS_ENGINE:-}"
  transport="${CURSOR_SKILLS_GIT_TRANSPORT:-}"

  if [[ -f "${config}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${config}"
    set +a
  fi

  [[ -n "${vault}" ]] && CURSOR_SKILLS_VAULT="${vault}"
  [[ -n "${url}" ]] && CURSOR_SKILLS_VAULT_URL="${url}"
  [[ -n "${engine}" ]] && CURSOR_SKILLS_ENGINE="${engine}"
  [[ -n "${transport}" ]] && CURSOR_SKILLS_GIT_TRANSPORT="${transport}"

  CURSOR_SKILLS_ENGINE="${CURSOR_SKILLS_ENGINE:-${ENGINE_ROOT}}"
  CURSOR_SKILLS_GIT_TRANSPORT="${CURSOR_SKILLS_GIT_TRANSPORT:-ssh}"
  export CURSOR_SKILLS_ENGINE CURSOR_SKILLS_GIT_TRANSPORT
  if [[ -n "${CURSOR_SKILLS_VAULT:-}" ]]; then
    export CURSOR_SKILLS_VAULT
  fi
  if [[ -n "${CURSOR_SKILLS_VAULT_URL:-}" ]]; then
    export CURSOR_SKILLS_VAULT_URL
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_vault() {
  [[ -n "${CURSOR_SKILLS_VAULT:-}" ]] || die "CURSOR_SKILLS_VAULT is unset. Set it in config.local.env."
  [[ -d "${CURSOR_SKILLS_VAULT}/.git" ]] || die "CURSOR_SKILLS_VAULT is not a git repo: ${CURSOR_SKILLS_VAULT}"
  CURSOR_SKILLS_VAULT="$(cd "${CURSOR_SKILLS_VAULT}" && pwd)"
  export CURSOR_SKILLS_VAULT
}

safe_skill_name() {
  local name="$1"
  [[ "${name}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "refusing unsafe skill name: ${name}"
  [[ "${name}" != .* ]] || die "refusing unsafe skill name: ${name}"
}
