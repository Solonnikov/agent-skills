# agent-skills

A public collection of agent skills — reusable capabilities, prompts, and workflows for Claude Code and other agentic coding tools.

This repo is a place to share, experiment with, and iterate on skills that extend what an AI agent can do out of the box: coding patterns, review checklists, automation recipes, domain-specific helpers, and more.

## What is a skill?

A skill is a self-contained package of instructions (and optional scripts, templates, or config) that an agent can load on demand to perform a specific task well. Think of it like a specialized mini-manual the agent pulls in only when relevant — keeping the base context lean while making deep expertise available when needed.

Typical contents of a skill:

- **`SKILL.md`** — the instructions the agent reads (what the skill does, when to use it, how to apply it).
- **Supporting files** — scripts, templates, examples, or reference docs the skill points to.

## Repo structure

```
agent-skills/
├── README.md
└── skills/
    └── <skill-name>/
        ├── SKILL.md
        └── ...            # optional scripts, templates, examples
```

Each skill lives in its own directory under `skills/` and is documented by its own `SKILL.md`.

## Using a skill

Copy the skill directory into your agent's skills folder (e.g. `~/.claude/skills/` for Claude Code), or reference it directly from a project. Then invoke it the way your agent expects — for Claude Code, that's typically `/<skill-name>` or a natural-language request that matches the skill's trigger description.

## Contributing

Skills here are a work in progress and intentionally experimental. Pull requests, issues, and ideas are welcome.

When adding a new skill:

1. Create a new directory under `skills/`.
2. Add a `SKILL.md` with a clear name, one-line description, and instructions for when/how to use it.
3. Keep the scope tight — one skill, one job.
4. Include a short example or usage note so others can tell at a glance whether it fits their workflow.

## License

MIT — see [LICENSE](LICENSE) if present, otherwise treat contents as MIT-licensed unless a specific skill states otherwise.
