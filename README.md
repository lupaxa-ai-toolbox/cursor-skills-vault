<p align="center">
    <a href="https://github.com/lupaxa-ai-toolbox">
        <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/organisations/ai-toolbox/readme-logo.png" alt="Organisation Logo" />
    </a>
</p>

<h1 align="center">Cursor Skills Vault</h1>

Share Cursor agent skills from one private vault across a team.

The vault is a private git repository of `skills/<name>/` directories. This engine installs those skills into Cursor on each machine.

## Setup

```bash
git clone https://github.com/lupaxa-ai-toolbox/cursor-skills-vault.git
cd cursor-skills-vault
cp config.example.env config.local.env
```

Edit `config.local.env` and set `CURSOR_SKILLS_VAULT` to the directory for your private vault. Set `CURSOR_SKILLS_VAULT_URL` when that directory does not exist yet and `setup` should clone it.

```bash
./bootstrap.sh setup
./bootstrap.sh import my-skill /absolute/path/to/my-skill
./bootstrap.sh install
./bootstrap.sh status
```

`./bootstrap.sh update` pulls the engine and the vault, then installs again.

Start a new Cursor agent after setup so the skill loads.

<a href="https://github.com/the-lupaxa-project">
    <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/components/footer-for-child-orgs.svg" alt="The Lupaxa Project Footer" width="100%" />
</a>
