# Agents

Role-based agent definitions — generic, framework-agnostic. Each agent describes a role's responsibilities, decisions, constraints, and handoff rules.

For framework- or domain-specific knowledge (Angular testing patterns, Web3 wallet flows, NgRx scaffolding), see [`../skills/`](../skills). Agents are *who does the work*; skills are *how it's done in a given stack*.

## Layout

```
agents/
└── software-development/   # generic software roles (start here; add more domains as we grow)
```

## Using an agent

Copy the `.md` file into your host tool's agents folder — for Claude Code: `~/.claude/agents/` (user-wide) or `<project>/.claude/agents/` (per project). The narrative-format files describe a role; adapt them as prompts or convert them to your host's native agent format.

For a one-command install of everything in this repo into `~/.claude/`, see [`../install.sh`](../install.sh).
