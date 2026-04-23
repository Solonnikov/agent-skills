# Software development agents

Generic role definitions for a typical software team. No framework lock-in. For Angular-, NgRx-, or Web3-specific how-to guidance, see [`../../skills/`](../../skills).

## Agents

| Agent | Role |
|-------|------|
| [frontend-developer](./frontend-developer.md) | Builds production UI, client state, and API integration. |
| [backend-developer](./backend-developer.md) | Builds production services, data access, and API contracts. |
| [test-engineer](./test-engineer.md) | Writes and reviews tests. Enforces the test pyramid. |
| [code-reviewer](./code-reviewer.md) | Reviews diffs for quality, safety, and conventions. |
| [security-reviewer](./security-reviewer.md) | Reviews changes for security risks before they ship. |
| [ui-reviewer](./ui-reviewer.md) | Reviews UI for design consistency, accessibility, and responsive behavior. |
| [web3-auditor](./web3-auditor.md) | Audits wallet integrations, crypto payment flows, and on-chain interactions. |

## Format

Role agents use a narrative format: **Identity → Role summary → Responsibilities → Decision framework → Constraints → Failure modes → Outputs → Completion and handoff → Collaboration → Escalation**.

Some agents (`ui-reviewer`, `web3-auditor`) include YAML frontmatter so they drop directly into `~/.claude/agents/`. The rest are prompt material you can adapt to your host's agent system.
