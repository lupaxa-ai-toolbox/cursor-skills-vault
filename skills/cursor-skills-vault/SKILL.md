---
name: cursor-skills-vault
description: >-
  Store shared Cursor skills in the team's private skills vault and install
  them on this machine. Use when creating a skill, installing skills, or
  setting up cursor-skills-vault.
---

# cursor-skills-vault

Team skills live in one private git vault under `skills/<name>/SKILL.md`.
Installing copies them into `~/.cursor/skills/` and copies any `rules/*.mdc`
into `~/.cursor/rules/`.

## When adding a skill

Write the skill in the vault, not only under `~/.cursor/skills/`. A skill that
exists only on this machine is not shared.

```bash
ENGINE="${CURSOR_SKILLS_ENGINE:-$HOME/cursor-skills-vault}"
"$ENGINE/scripts/import-skill.sh" <name> <source-directory>
"$ENGINE/scripts/sync-vault.sh"
"$ENGINE/scripts/install-skills.sh" <name>
```

`<name>` is letters, numbers, `.`, `_`, and `-`, and it must start with a letter or number. The source directory must contain `SKILL.md`.

If `sync-vault.sh` prints `remote is missing`, leave the commit local and say so.

Do not copy Lupaxa private skills into this vault. This engine stores only the skills the team chooses to share.

## Example prompts

- `Add this skill to the cursor-skills vault`
- `Install skills from the cursor-skills vault`
- `Set up cursor-skills-vault on this machine`
