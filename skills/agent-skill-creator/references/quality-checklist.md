# Quality checklist

Run through this before merging a skill PR.

## Structure

- [ ] Folder is `skills/<kebab-case-name>/`.
- [ ] `SKILL.md` exists and is under ~80 lines.
- [ ] At least one file in `references/` if the skill has any non-trivial depth.
- [ ] No files outside `SKILL.md` and `references/*.md` (no `package.json`, no source code, no binaries).

## Frontmatter

- [ ] Frontmatter present and valid YAML.
- [ ] `name` matches the folder name exactly.
- [ ] `description` starts with an action verb.
- [ ] `description` includes "Use when ..." with at least two comma-separated trigger scenarios.
- [ ] No fluff adjectives ("comprehensive", "state-of-the-art", "production-grade") in `description`.

## SKILL.md content

- [ ] Opens with a one-paragraph summary of what the skill is for.
- [ ] Has a "When to use" section with concrete scenarios, not generalities.
- [ ] Has an actionable workflow (numbered or clearly ordered).
- [ ] Has a "Non-negotiable rules" section with hard constraints.
- [ ] Has a "References" section where every link is described by its content, not by filename.
- [ ] No emojis, no decorative boxes, no "Note:" / "Warning:" callouts (prefer plain prose).

## References

- [ ] Each reference is on a single topic, named for that topic.
- [ ] No reference duplicates content already in SKILL.md.
- [ ] Code examples use realistic placeholders, not hard-coded secrets, addresses, or project-specific names.
- [ ] Cross-references between this skill's references are one-level deep (no chains).

## Integration with the repo

- [ ] Added to `skills/README.md` table with a one-line description.
- [ ] Added to root `README.md` skills list.
- [ ] Linked from any related skill's "See also" section where sensible.

## Verification

- [ ] Reading SKILL.md alone, an agent can perform the skill's core workflow without loading references.
- [ ] Reading SKILL.md + references, the combined content doesn't contradict itself.
- [ ] Every reference link in SKILL.md resolves.
- [ ] Every code example would actually compile / run (or is clearly marked as pseudo-code).
