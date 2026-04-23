# Meeting types

Different meetings want different structures. Match the meeting type.

## Standup (daily sync)

- **Goal**: surface blockers, align on the day.
- **Shouldn't be**: a status report.

### Template

```
# Standup — YYYY-MM-DD

**Blockers**: [Who's stuck, on what, who can help.]

**Today**: [Each person, one line on what they're focused on.]

**Yesterday**: [Only if relevant — usually skip.]

**Parking lot**: [Topics raised that need a real meeting, not this one.]
```

### Rules

- 15 min max. If longer, it's not standup.
- Parking lot > going deep in the meeting. Take the deep conversation offline.
- "Yesterday" is optional — recency bias makes it the least useful field.
- Distributed teams: async standup in a Slack channel often beats a video call. Written forces brevity.

## 1-on-1

- **Goal**: report-up or peer communication; growth; blockers that aren't public.
- **Shouldn't be**: status update in disguise (that's what standup is for).

### Template (manager ←→ report)

```
# 1-on-1 — @alice ←→ @bob — YYYY-MM-DD

## Topics from [report]
- [Their agenda first; this meeting is for them.]

## Topics from [manager]
- [Their agenda second.]

## Discussion
- [Short summary. Keep personal things personal.]

## Action items
| Owner | Task | Due |
|-------|------|-----|
```

### Rules

- Report sets the agenda first.
- Keep the notes private to the two attendees unless there's a reason to share.
- Cancel if there's nothing to discuss — recurring 1-on-1 is a habit, not a contract.
- Take notes in a shared doc both can edit. Fills in across weeks; visible context next time.

## Retro (retrospective)

- **Goal**: identify what to change. Process, not people.
- **Shouldn't be**: blame session or feel-good ritual.

### Template

```
# Retro — [PROJECT / SPRINT] — YYYY-MM-DD

## What went well
- [Specific, behavior-focused. "X worked" not "X is great".]

## What didn't go well
- [Specific, behavior-focused. "Y was late because Z".]

## What to change
- [Actionable, owned, with a deadline.]

## Action items
| Owner | Task | Due |
|-------|------|-----|

## Follow-up on previous retro's actions
- [Did we do them? Did they help? Drop, continue, or revise?]
```

### Rules

- Last section — follow-up on previous actions — is the most important. Otherwise retros produce ideas that never ship.
- No "team should" statements. Every change has an owner.
- Personal criticisms off the record. Behavior patterns in.
- Timebox it. 45–60 min max.

## Planning (sprint or quarter)

- **Goal**: commit to what gets done by when, by whom.
- **Shouldn't be**: discussing features without scoping.

### Template

```
# [Quarter or Sprint] Planning — YYYY-MM-DD

**Capacity**: [Available person-weeks, accounting for holidays / known absences.]
**Goal**: [One-sentence north star for the period.]

## Commitments (definitely shipping)
| Owner | Item | Est. | Due |
|-------|------|------|-----|

## Stretch (if capacity allows)
| Owner | Item | Est. | Due |

## Cut (discussed but not this period)
- [Why cut — capacity, priority, dependencies.]

## Risks
- [Known risks, with mitigation / owner.]

## Action items
| Owner | Task | Due |
```

### Rules

- Estimates in days or weeks, not hours. Hour-precision is false precision.
- Cut items get documented so they're not rediscovered next planning as "new" ideas.
- Risks need owners; ignored risks realize themselves.

## Kickoff

- **Goal**: establish scope, roles, timeline for new work.
- **Shouldn't be**: detailed design discussion.

### Template

```
# Kickoff — [PROJECT] — YYYY-MM-DD

**Team**: [@names with roles]
**Deadline**: [Target date + must-hit vs nice-to-hit]
**Success looks like**: [Measurable outcome.]

## Scope — in
- [Clear bullets.]

## Scope — out
- [Explicit non-goals. Matters more than the "in" section.]

## Roles
- Tech lead: @...
- Project manager: @...
- Design: @...
- Stakeholders: @...

## Dependencies
- [What / who are we waiting on?]

## Timeline
- [Milestone dates — design done, alpha, beta, GA.]

## Action items
| Owner | Task | Due |

## Risks + mitigations
- [Known risks now.]
```

### Rules

- "Scope — out" prevents scope creep better than "scope — in". Be explicit about non-goals.
- Success metric baked in at kickoff. Retrofitting one later leads to everyone grading on a different curve.

## Status update / review

- **Goal**: align stakeholders on progress; surface risks.
- **Shouldn't be**: reading a report aloud.

### Template

```
# [PROJECT] Status — YYYY-MM-DD

## Summary (one sentence)
- [On track / at risk / off track, with reason.]

## Progress since last update
- [Concrete shipped items.]

## Current focus
- [What's happening this week.]

## Risks / blockers
- [What might slip and why.]

## Asks
- [What the team needs from stakeholders — decision, unblock, introduction, etc.]
```

### Rules

- Pre-send the written update; use the meeting time for questions + asks, not reading.
- "Asks" section is the most important. Updates without asks are just reporting.
- Be direct about at-risk / off-track. Sugar-coated updates train stakeholders to distrust the green status.

## Decision meeting

- **Goal**: make a specific decision.
- **Shouldn't be**: open-ended exploration.

### Template

```
# Decision: [WHAT WE'RE DECIDING] — YYYY-MM-DD

**Decision required by**: [Date]
**Decision maker**: @name (one person, unless genuinely shared)

## Options
1. [Option A — one-paragraph summary.]
2. [Option B — one-paragraph summary.]
3. [Option C — one-paragraph summary.]

## Criteria
- [What we're evaluating against: cost, speed, reversibility, risk.]

## Recommendation
- [Recommended option + reason. Optional; often provided by RFC author.]

## Discussion notes
- [Any concerns raised, counter-proposals.]

## Decision
- Chose [X]. Reason: [one sentence].
- Reconsider: [Trigger that would cause us to revisit.]
```

### Rules

- One decision per meeting. If there are three decisions, three meetings.
- Decision-maker named in advance. Discussion is input; decision is theirs.
- Capture the *reason* for the decision — future readers need it more than the decision itself.
- Capture what would make the team revisit the decision. This is the single most-valuable field long-term.
