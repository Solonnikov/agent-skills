# Agents

Role-based agent prompts grouped by domain. Each agent is a single Markdown file defining a specialized persona, process, and output format — ready to drop into Claude Code's `.claude/agents/` folder (or an equivalent subagent system).

## Layout

```
agents/
├── software-development/   # broad software roles (frontend, backend, test, review, ...)
├── frontend/               # frontend-specific specialists
└── web3/                   # blockchain / wallet / crypto specialists
```

## Available agents

### software-development/
| Agent | Role |
|-------|------|
| [frontend-developer](./software-development/frontend-developer.md) | Implements UI features end-to-end with modern frontend frameworks. |
| [test-engineer](./software-development/test-engineer.md) | Writes and reviews tests. Enforces the test pyramid and TDD when asked. |
| [code-reviewer](./software-development/code-reviewer.md) | Reviews diffs for quality, security, and convention adherence. |

### frontend/
| Agent | Role |
|-------|------|
| [angular-code-reviewer](./frontend/angular-code-reviewer.md) | Angular-specific code review (NgRx, RxJS, standalone components, inject(), DI). |
| [angular-test-writer](./frontend/angular-test-writer.md) | Generates Jest specs for Angular components, services, pipes, and NgRx. |
| [ui-reviewer](./frontend/ui-reviewer.md) | Reviews templates and styles for design consistency, a11y, responsiveness, i18n. |

### web3/
| Agent | Role |
|-------|------|
| [web3-auditor](./web3/web3-auditor.md) | Audits wallet integrations, crypto payment flows, and on-chain interactions for security issues. |

## Using an agent

Copy the `.md` file into your agent host's folder (for Claude Code: `~/.claude/agents/` or `<project>/.claude/agents/`) and invoke it by name. The YAML frontmatter declares the agent name, trigger description, and tool scope.
