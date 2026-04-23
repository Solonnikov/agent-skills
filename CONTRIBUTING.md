# Contributing

This is the full working flow for `agent-skills`. Follow this on any machine and you won't miss a step.

## Branch protection

`main` is protected. You can't push to it directly — every change goes through a pull request. Branch protection rules:

- No direct pushes to `main`.
- No force pushes.
- No branch deletion.
- 0 required reviews (solo-friendly).
- Admin bypass allowed for emergencies only.

## Standard workflow for any change

1. **Sync main**

   ```bash
   git checkout main
   git pull
   ```

2. **Create a feature branch** — `feat/` for features, `fix/` for fixes, `docs/` for docs-only, `chore/` for tooling.

   ```bash
   git checkout -b feat/<short-description>
   ```

3. **Make changes, commit, push.**

   ```bash
   git push -u origin feat/<short-description>
   ```

4. **Open a PR with a descriptive title.** PR titles become release notes via `gh release create --generate-notes` — write them cleanly.

   ```bash
   gh pr create --title "..." --body "..."
   ```

5. **Merge.** Squash-merge and delete the branch:

   ```bash
   gh pr merge <n> --squash --delete-branch
   ```

6. **Decide whether to cut a release** (see below). Not every merge needs one.

## Adding a new skill

1. Read [`skills/agent-skill-creator/SKILL.md`](./skills/agent-skill-creator/SKILL.md) for the format. That's the meta-skill — it's the authoritative spec.
2. Create `skills/<kebab-case-name>/SKILL.md` with YAML frontmatter:

   ```markdown
   ---
   name: <kebab-case-name>
   description: <what it does>. Use when <trigger scenarios>.
   ---
   ```

3. Keep `SKILL.md` under ~80 lines: summary, "When to use", workflow, non-negotiable rules, references.
4. Put long-form depth — templates, checklists, cheatsheets — in `references/*.md`.
5. In SKILL.md, link to each reference **by description, not file name**:

   ```markdown
   ## References

   - [Structure](./references/structure.md) — roles, delimiters, section ordering.
   ```

6. Update `skills/README.md` — add the new skill to the category table.
7. Update root `README.md` — add the new skill to the main skills table.
8. Run the [quality checklist](./skills/agent-skill-creator/references/quality-checklist.md) before opening the PR.

## Adding a new agent

1. `agents/software-development/<role>.md`.
2. Narrative format: **Identity → Role summary → Responsibilities → Decision framework → Constraints → Failure modes → Outputs → Completion and handoff → Collaboration → Escalation.**
3. Optional YAML frontmatter for Claude Code compatibility (`name`, `description`, `tools`, `model`).
4. Update `agents/software-development/README.md` and root `README.md` with the new agent.

## Release rules (semver)

Semver: `vMAJOR.MINOR.PATCH`.

| Change | Bump |
|--------|------|
| Fixes, clarifications, typos, small wording | **Patch** — `v0.4.1` |
| New skill, new agent, backwards-compatible restructure | **Minor** — `v0.5.0` |
| Breaking changes to folder layout, SKILL.md format, agent format | **Major** — `v1.0.0` |

### Release cadence

- **Not every merge is a release.** Releases are publish moments.
- Cut a release when meaningful change has accumulated — typically every few PRs, or every 1–2 weeks of activity.
- Decision tree:
  - Typo / link fix → merge, no release.
  - Small clarification → merge, batch into the next patch.
  - **New skill or agent → merge, cut a minor release.**
  - Restructure → cut a major release with migration notes.
- If nothing meaningful changed in a month, don't cut a release.

### Cutting a release

```bash
git checkout main
git pull
git tag -a vX.Y.Z -m "vX.Y.Z — <short summary>"
git push origin vX.Y.Z
gh release create vX.Y.Z --title "vX.Y.Z — <title>" --generate-notes
```

`--generate-notes` builds the release body from merged PR titles since the last tag. **Clean PR titles = clean release notes.**

### Release immutability

- **Never re-tag or delete a published version.** If a release ships broken, cut the next patch.
- **Never skip version numbers.** Sequential only.

## Conventions

### File naming

- Skill folders and agent files use **kebab-case**: `prompt-engineering-patterns`, `frontend-developer.md`.
- References use kebab-case too: `structure.md`, `core-web-vitals.md`.
- No underscore-separated names, no CamelCase.

### SKILL.md structure

- YAML frontmatter with `name` (matches folder) and `description` (one sentence: `<what>. Use when <trigger>.`).
- Under ~80 lines.
- Sections: one-paragraph summary → When to use → Before you start (optional) → Workflow → Non-negotiable rules → References.
- No emojis. No marketing adjectives ("comprehensive", "production-grade"). No decorative headers or "Note:" callouts — prefer plain prose.

### References

- One topic per file.
- Named for the topic, not numbered.
- No duplication between SKILL.md and a reference.
- Code examples use realistic placeholders (`<Feature>`, `<Token>`), never real addresses, secrets, or project-specific names.

### Commit messages

- First line: what changed, imperative mood. Under ~72 chars.
- Optional body after a blank line with the why + non-obvious details.
- Include a trailing `Co-Authored-By: Claude Opus ... <noreply@anthropic.com>` if the commit was AI-assisted.

### PR titles

Since they become release notes:

- Good: `Add rag-pipeline-setup skill`
- Good: `Fix wagmi-contract-interaction: simulate → write pattern was backwards`
- Good: `v0.5.0: AI tooling skills (RAG + evals)`
- Bad: `Updates`
- Bad: `misc changes`

## Installing this repo on a new machine

See the README's [Install section](./README.md#install). The short version:

```bash
git clone https://github.com/Solonnikov/agent-skills.git
cd agent-skills
./install.sh                        # Claude Code, user-wide
./install.sh --target cursor        # Cursor in current dir
./install.sh --target copy --dest ./foo
```

## Environment setup

For the release flow to work from any PC, you need:

- `git` — obviously.
- [`gh`](https://cli.github.com) — GitHub CLI. Install via Homebrew (`brew install gh`) or your package manager.
- Authenticated gh: `gh auth login`, pick **GitHub.com → HTTPS → Login with web browser**.
- `gh auth setup-git` — so `git push` can use the gh token instead of prompting.

That's it. Every step in this doc runs after those three are in place.
