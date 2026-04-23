# Software development agents

Role-style agent definitions for a typical software team. Technology-agnostic — frame the work in terms of responsibilities, decisions, and handoff, not specific frameworks.

For framework-specific specialists, see:

- [`../frontend/`](../frontend) — Angular-focused reviewers and test writers.
- [`../web3/`](../web3) — wallet, payment, and on-chain auditors.

## Agents

- [frontend-developer](./frontend-developer.md) — builds production UI, state, and API integration.
- [backend-developer](./backend-developer.md) — builds production services, data access, and API contracts.
- [test-engineer](./test-engineer.md) — writes and reviews tests; enforces the test pyramid.
- [code-reviewer](./code-reviewer.md) — reviews diffs for quality, correctness, and convention adherence.
- [security-reviewer](./security-reviewer.md) — reviews changes for security risks before they ship.

## Format

These are narrative role definitions, not Claude Code configs. They use the standard sections: Identity → Role summary → Responsibilities → Decision framework → Constraints → Failure modes → Outputs → Completion and handoff → Collaboration → Escalation. No YAML frontmatter. Use them as prompts or as copy material when writing framework-specific agents for your own projects.
