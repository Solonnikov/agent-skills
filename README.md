# agent-skills

[![GitHub release](https://img.shields.io/github/v/release/Solonnikov/agent-skills?sort=semver)](https://github.com/Solonnikov/agent-skills/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](#license)

A public, experimental collection of **agent skills** and **role agents** for AI coding tools — Claude Code, Cursor, Codex, Copilot, Aider, or any LLM you paste context into. General-purpose roles alongside specialized material in areas I work in daily: frontend (Angular, NgRx) and Web3 (wallet integrations, smart contract interaction, payments).

Work in progress. Use as starting material; verify what you adopt.

## Install

One command pulls everything into your tool's agents/skills folder.

**Claude Code (user-wide):**
```bash
curl -fsSL https://raw.githubusercontent.com/Solonnikov/agent-skills/main/install.sh | bash
```

**Other targets** (run the installer with flags):
```bash
git clone https://github.com/Solonnikov/agent-skills.git
cd agent-skills
./install.sh --target cursor              # .cursor/rules/ in the current dir
./install.sh --target copy --dest ./foo   # plain copy to a path
./install.sh --agents-only
./install.sh --skills-only
./install.sh --help
```

Default mode is **symlink from a clone** (so `git pull` updates your local copy) and **copy when curl-piped**.

**Any other AI / LLM:** the content is plain Markdown. Open any file, paste into your tool's system prompt, context, or rules section.

## What's here

```
agent-skills/
├── install.sh
├── agents/
│   └── software-development/     # generic role agents (no framework lock-in)
└── skills/                       # reusable how-to skills, one folder each
    ├── agent-skill-creator/
    ├── ngrx-feature-scaffold/
    ├── reown-appkit-web3/
    └── wagmi-contract-interaction/
```

**Skills** — procedures, patterns, templates, and checklists an agent loads on demand. Each skill is a folder with a tight `SKILL.md` and long-form `references/`.

**Agents** — role-style Markdown definitions (who is responsible for what, how they decide, how they hand off). Generic by design; framework-specific knowledge lives in skills, not in agent descriptions.

### Skills

| Skill | Purpose |
|-------|---------|
| [agent-skill-creator](./skills/agent-skill-creator/SKILL.md) | Meta-skill for authoring new skills in this repo with consistent format. |
| [ngrx-feature-scaffold](./skills/ngrx-feature-scaffold/SKILL.md) | Scaffold a complete NgRx feature (actions, reducer, effects, selectors, facade, tests). |
| [reown-appkit-web3](./skills/reown-appkit-web3/SKILL.md) | Integrate `@reown/appkit` multi-chain wallets (EVM, Solana, Bitcoin). |
| [wagmi-contract-interaction](./skills/wagmi-contract-interaction/SKILL.md) | Read, write, and watch EVM smart contracts with wagmi v2. |

### Agents

[`agents/software-development/`](./agents/software-development) — `frontend-developer`, `backend-developer`, `test-engineer`, `code-reviewer`, `security-reviewer`, `ui-reviewer`, `web3-auditor`.

## Tool compatibility

| Tool | How the repo drops in |
|------|------------------------|
| **Claude Code** | `./install.sh` — files go to `~/.claude/agents/` and `~/.claude/skills/`. Agents with YAML frontmatter are directly invocable. |
| **Cursor** | `./install.sh --target cursor` — files go to `./.cursor/rules/`. Rename to `.mdc` and adjust frontmatter per Cursor docs if needed. |
| **Codex / Copilot / Aider / Continue** | `./install.sh --target copy --dest <your-tool's-path>`, or copy the Markdown content into your tool's context/rules/prompt field. |
| **Any other LLM** | Open the file in GitHub, copy the Markdown, paste into your system prompt or context. |

Content is written in plain Markdown so every tool that reads text can use it.

## Contributing

Pull requests and ideas welcome.

**Adding a new skill** — see [`agent-skill-creator`](./skills/agent-skill-creator/SKILL.md) for the full format.

1. Create `skills/<kebab-case-name>/SKILL.md` with YAML frontmatter (`name`, `description`).
2. Keep `SKILL.md` tight (<80 lines). Put depth in `references/*.md`.
3. Link references by description, not file name.
4. Add the skill to this README and `skills/README.md`.

**Adding a new agent** — `agents/software-development/<role>.md`, narrative format (Identity → Role summary → Responsibilities → Decision framework → Constraints → Failure modes → Outputs → Completion and handoff → Collaboration → Escalation). Optional YAML frontmatter for Claude Code compatibility.

Direct pushes to `main` are blocked — changes land through pull requests.

## Releases

Semver: [`vMAJOR.MINOR.PATCH`](https://semver.org/).

- **Patch** (`v0.1.1`) — fixes, clarifications, small improvements to existing content.
- **Minor** (`v0.2.0`) — new skill, new agent, backwards-compatible restructuring.
- **Major** (`v1.0.0`+) — breaking changes to folder layout or file format.

Cutting a release:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
gh release create vX.Y.Z --generate-notes
```

`--generate-notes` builds the release body from merged PR titles since the last tag. Clean PR titles = clean release notes.

Not every merge is a release — cut one when meaningful change has accumulated (new skill, new agent, or a batch of small improvements).

## Disclaimer

Most of the content here is AI-generated or produced with significant AI assistance, then reviewed and edited. It is not a guarantee of accuracy, completeness, or fit for your use case — treat it like any other generated material and verify what you adopt.

These skills and agents are **experimental**. Their behavior and side effects are not fully characterized. Content may be wrong for your situation or unsafe without human review (running commands, changing files, applying security-related guidance). This is not legal, financial, or professional advice.

**Do not use or apply this material on systems you do not own or are not authorised to change.** Use at your own risk.

## License

MIT. Individual skills or agents may state otherwise; check the file if in doubt.
