# agent-skills

[![GitHub release](https://img.shields.io/github/v/release/Solonnikov/agent-skills?sort=semver)](https://github.com/Solonnikov/agent-skills/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](#license)

A public, experimental collection of **agent skills** and **role agents** for Claude Code and other agentic coding tools. General-purpose content alongside specialized material in areas I work in daily — Angular (with NgRx) and Web3 (wallet integrations, on-chain flows).

This repository is a work in progress and a build-in-public snapshot. Use any of it as starting material, copy, or adapt — but verify what you adopt.

## What's here

```
agent-skills/
├── agents/                   # Role-style agent prompts
│   ├── software-development/ # Generic roles: frontend, backend, test, review, security
│   ├── frontend/             # Angular-specific: code review, test writer, UI review
│   └── web3/                 # Web3 security: wallet / payment / on-chain audit
└── skills/                   # Reusable how-to skills
    ├── ngrx-feature-scaffold/
    └── reown-appkit-web3/
```

**Skills** are reusable "how-to" instructions an agent loads on demand — procedures, patterns, templates, and checklists. Each skill is a folder with a tight [`SKILL.md`](./skills/ngrx-feature-scaffold/SKILL.md) and long-form `references/`.

**Agents** are role-style Markdown definitions — who is responsible for what, how they decide, and how they hand off. Generic roles under [`agents/software-development/`](./agents/software-development) have no framework lock-in. Specialized agents under [`agents/frontend/`](./agents/frontend) and [`agents/web3/`](./agents/web3) ship with Claude Code frontmatter and drop straight into `.claude/agents/`.

### Skills

| Skill | Purpose |
|-------|---------|
| [ngrx-feature-scaffold](./skills/ngrx-feature-scaffold/SKILL.md) | Scaffold a complete NgRx feature (actions, reducer, effects, selectors, facade, tests) using modern Angular patterns. |
| [reown-appkit-web3](./skills/reown-appkit-web3/SKILL.md) | Integrate `@reown/appkit` multi-chain wallets (EVM via wagmi, Solana, Bitcoin) — init, state, signing, security. |

### Agents

**Generic role agents** — [`agents/software-development/`](./agents/software-development): `frontend-developer`, `backend-developer`, `test-engineer`, `code-reviewer`, `security-reviewer`.

**Angular specialists** — [`agents/frontend/`](./agents/frontend): `angular-code-reviewer`, `angular-test-writer`, `ui-reviewer`.

**Web3 specialists** — [`agents/web3/`](./agents/web3): `web3-auditor`.

## Using this repo

Copy the skill or agent file into your host tool:

- **Claude Code** — agents go in `~/.claude/agents/` (user-wide) or `<project>/.claude/agents/` (per project). Skills go in `~/.claude/skills/` or the project equivalent.
- **Other agentic tools** — read the Markdown and adapt to your tool's conventions.

## Contributing

Pull requests and ideas welcome. When adding a new skill:

1. Create a folder under `skills/` with a `SKILL.md` that includes YAML frontmatter: `name` (kebab-case) and `description` (`<what it does>. Use when <trigger>.`).
2. Keep `SKILL.md` tight and action-oriented; put depth in `references/*.md`.
3. Link references by description, not file name.

When adding a new agent:

1. Generic role → `agents/software-development/` in narrative format (Identity / Role summary / Responsibilities / Decision framework / Constraints / Failure modes / Outputs / Completion and handoff / Collaboration / Escalation).
2. Framework-specific → `agents/<domain>/` with Claude Code YAML frontmatter (`name`, `description`, `tools`, `model`).

Direct pushes to `main` are blocked — changes land through pull requests.

## Releases

Releases follow [semver](https://semver.org/):

- **Patch** (`v0.1.1`) — fixes, clarifications, small improvements to existing skills/agents.
- **Minor** (`v0.2.0`) — new skills, new agents, backwards-compatible restructuring.
- **Major** (`v1.0.0` and beyond) — breaking restructures of the folder layout or agent format.

Cutting a release:

```bash
git tag v0.2.0
git push origin v0.2.0
gh release create v0.2.0 --generate-notes
```

The first two commands mark the tag; `gh release create --generate-notes` builds release notes from merged PR titles since the last tag. The release then shows up in the repo's **Releases** sidebar.

## Disclaimer

Most of the content here is AI-generated or produced with significant AI assistance, then reviewed and edited. It is not a guarantee of accuracy, completeness, or fit for your use case — treat it like any other generated material and verify what you adopt.

These skills and agents are **experimental**. Their behavior and side effects are not fully characterized. Content may be wrong for your situation or unsafe without human review (for example: running commands, changing files, or applying security-related guidance). This is not legal, financial, or professional advice.

**Do not use or apply this material on systems you do not own or are not authorised to change.** Use at your own risk.

## License

MIT — see [LICENSE](./LICENSE) if present. Individual skills or agents may state otherwise; check the file if in doubt.
