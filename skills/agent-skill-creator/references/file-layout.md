# File layout

```
skills/
└── <skill-name>/
    ├── SKILL.md
    └── references/
        ├── <topic-1>.md
        ├── <topic-2>.md
        └── ...
```

## `SKILL.md`

The only file an agent loads when the skill is invoked. Keep it operational.

Standard structure:

```markdown
---
name: ...
description: ...
---

# <Title>

<One-paragraph intro: what the skill is for.>

## When to use

- Bullet list of concrete trigger scenarios.

## Before you start

<Optional: the information or inputs the skill needs from the user.>

## Authoring workflow  (or: Implementation workflow, Review workflow — name it for the job)

1. Numbered steps.
2. Each step actionable, verifiable.

## Non-negotiable rules

- Bullet list of hard rules — things that, if violated, invalidate the output.

## References

- [Link text](./references/file.md) — one-line description of what the reference covers.
```

Keep this under 80 lines when you can. If it grows past that, push content into references.

## `references/`

Every reference is a single Markdown file on a single topic. File names are kebab-case, match the topic — `templates.md`, `effects.md`, `checklist.md`.

### When to create a reference

- Long templates (more than ~40 lines of code).
- Checklists (more than ~5 items, or grouped into categories).
- Cheatsheets (decision tables, operator comparisons).
- Step-by-step procedures that would crowd SKILL.md.
- Background context ("why this pattern exists") useful to some users but not all.

### When NOT to create a reference

- If the content is short and always relevant, inline it in SKILL.md.
- If the reference would only link to external docs, write a one-line pointer in SKILL.md instead.
- If the content is general programming advice not specific to this skill — link out, don't reproduce.

## Depth, not breadth

Prefer fewer, deeper references over many shallow ones. A skill with 3 focused references (`templates.md`, `errors.md`, `checklist.md`) is easier to navigate than one with 10 overlapping files.

## What NOT to put in a skill folder

- Generated code, build output, test fixtures.
- Images or screenshots (unless the skill genuinely needs them — prefer text).
- Large example projects — link to a separate repo instead.
- Anything that would be stale within 6 months (framework versions, exact API signatures from a library).
