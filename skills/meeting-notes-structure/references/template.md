# Template

Copy-paste, fill in the blanks, keep it short.

## Universal template

```markdown
# [Meeting Name] — [YYYY-MM-DD]

**Attendees**: @alice, @bob, @charlie
**Absent**: @dana (expected; out sick)
**Purpose**: [One sentence: what this meeting is for.]
**Duration**: 45 min

---

## Action items

| Owner | Task | Due |
|-------|------|-----|
| @alice | [Specific, verb-first] | YYYY-MM-DD |
| @bob   | [Specific, verb-first] | YYYY-MM-DD |

## Decisions

- [Decision in one sentence. Reason in one sentence.]
- [Decision. Reason.]

## Discussion notes

[Only bits that matter for context. Keep it short. If there's nothing worth preserving, delete this section.]

## Open questions

- [Question.] — owner: @alice, target: YYYY-MM-DD.

## Next meeting

[Date], [time]. Agenda: [one-line purpose].
```

## Shorter variant — standup (daily)

```markdown
# Standup — 2026-04-23

**Attendees**: @alice, @bob, @charlie

## Blockers

- @bob blocked on design handoff (pinged @dana).

## Today

- @alice: finishing the RFC draft.
- @bob: pairing with @charlie on auth bug once unblocked.
- @charlie: reviewing PR #234, then auth bug.

## Yesterday (only if relevant)

[Usually skip. Keep standup about today + blockers.]
```

## Shorter variant — 1-on-1

```markdown
# 1-on-1 — @alice ←→ @bob — 2026-04-23

## Topics from @alice

- Concerned about the rollout timeline.
- Wants to explore the staff engineer track.

## Topics from @bob

- Feedback on the RFC review.
- Thinking about Q3 planning.

## Discussion

- [One or two sentences on what mattered. Keep personal things personal — notes go to both of you only.]

## Action items

| Owner | Task | Due |
|-------|------|-----|
| @bob | Connect @alice with @staff-dave for coffee chat | 2026-04-30 |
| @alice | Draft a 6-month plan for the staff track | 2026-05-07 |

## Next 1-on-1: 2026-04-30.
```

## Longer variant — decision meeting (RFC review, architecture, planning)

```markdown
# RFC #42 Review — Data Pipeline Redesign — 2026-04-23

**Attendees**: @alice (author), @bob (architect), @charlie (DevOps), @dana (PM)
**Absent**: none
**Purpose**: Approve or request changes on RFC #42.
**Decision required by**: 2026-04-30.

---

## Summary

RFC proposes moving from monolithic pipeline to streaming (Kafka + Flink). Est. 8 weeks, 2 engineers.

## Action items

| Owner | Task | Due |
|-------|------|-----|
| @alice | Add rollback plan section to RFC | 2026-04-25 |
| @charlie | Get a cost estimate from AWS rep | 2026-04-28 |
| @bob | Review security implications with @eve | 2026-04-27 |

## Decisions

- Approved in principle, pending the items above.
- Agreed to use Flink (not Spark Streaming). Reason: team already has Flink expertise; lower onboarding.
- Rollback plan is a blocker — RFC won't merge without it.

## Open questions

- Cost at 10x traffic? — owner: @charlie, target: 2026-04-28.
- Data-retention policy under new model? — owner: @dana, target: 2026-05-01.

## Discussion notes

- @bob flagged that the monolithic pipeline's failure mode is "recoverable in 15 min"; streaming failures can be harder. Mitigation: dual-writes during migration period. ← This belongs in the RFC.
- @dana asked about customer-facing impact; @alice confirmed migration is transparent.

## Next meeting

2026-04-30, to approve final version. Agenda: review updated rollback plan + costs.
```

## Adaptation tips

- **Remove sections you don't use.** If there were no open questions, delete that section. Blank sections are noise.
- **One shared doc per recurring meeting, append new entries at top.** New readers see today first; history is one scroll away.
- **Link the doc in the meeting invite.** Everyone knows where to find it.
- **Pin action items** in Slack / Teams after the meeting. Doc gets archived; pinned messages get seen.
