# Brief template

Copy-paste, fill in, delete sections that don't apply.

## Standard template

```markdown
# Brief: [Question] — [YYYY-MM-DD]

## Question
[One sentence: what are we deciding, who needs the answer, by when.]

## TL;DR
[Recommendation in one sentence.]

## Recommendation
[Specific recommendation. Name the option. Optional: confidence level.]

## Reasoning
- [Strongest evidence point, with source reference.]
- [Next strongest.]
- [3–5 bullets total. Each should meaningfully move the decision.]

## Alternatives considered
- **Option B**: [one-line summary]. Pros: [...]. Cons: [...]. Why not: [one sentence].
- **Option C**: [one-line summary]. Pros: [...]. Cons: [...]. Why not: [one sentence].

## Risks and mitigations
- **Risk 1**: [what could go wrong]. Mitigation: [what to do].
- **Risk 2**: [...]. Mitigation: [...].

## Gaps
- [Specific thing you couldn't confirm. What you'd want to know.]
- [Another.]

## Trigger to revisit
[Specific event or data point that would change the answer.]

## Sources
- [Title] — [author / org] — [link] — [one-line credibility note].
- ...
```

## Worked example

```markdown
# Brief: Postgres vs MongoDB for user-profile service — 2026-04-23

## Question
Which primary datastore should we use for the new user-profile service? Decision needed by 2026-04-30 for sprint planning.

## TL;DR
Use Postgres. MongoDB's schema flexibility isn't worth the operational complexity at our scale.

## Recommendation
Use Postgres 16 with JSONB for the semi-structured fields. Confidence: high.

## Reasoning
- Our expected data shape is mostly relational (user → profile → settings), with one field (custom_attributes) that's semi-structured. Postgres JSONB handles that cleanly. [Source 3]
- Expected query patterns are 90% point lookups and joins. Postgres is a better fit for both than MongoDB. [Source 1]
- Team has 5 engineers familiar with Postgres, 0 with MongoDB. Estimated onboarding cost for MongoDB: 4–6 weeks. [Internal discussion 2026-04-21]
- Backup / recovery / observability tooling for Postgres is mature in our infra. MongoDB would require new tooling. [Source 2]
- At our projected scale (10M users, ~100 QPS), both options handle the load — not a differentiator.

## Alternatives considered
- **MongoDB**: Pros: flexible schema; strong horizontal scaling. Cons: team unfamiliarity; new tooling needed; relational queries are more awkward. Why not: relational use case; no schema-flexibility driver.
- **DynamoDB**: Pros: zero operational burden; matches AWS stack. Cons: inflexible query patterns; expensive at scale; limits on item size. Why not: requires rewriting query layer; cost model doesn't match our projected growth.

## Risks and mitigations
- **Risk**: JSONB queries on custom_attributes get slow if we add many fields. **Mitigation**: monitor; fallback to promoting hot fields into columns.
- **Risk**: Need horizontal scaling later. **Mitigation**: Postgres scales vertically far enough for our 3-year plan; read replicas are well-supported.

## Gaps
- Couldn't find hard numbers on JSONB query performance at 10M+ rows. Will need to benchmark in a sandbox.
- MongoDB Atlas vs self-hosted cost comparison is from 2024; pricing may have shifted.

## Trigger to revisit
If custom_attributes grows beyond 20 fields, or if we need schema flexibility for new features we can't predict now, re-evaluate MongoDB.

## Sources
1. "Relational vs document stores" — [author] — [link] — Database vendor comparison; author is ex-MongoDB, note the bias.
2. Internal runbook — SRE team, 2026-03-15 — our observability stack and what it supports.
3. Postgres JSONB docs — postgresql.org — official, authoritative.
4. "Scaling MongoDB to 10M users" — company blog, 2024-11 — relevant but pre-6.0 release.
```

## Tighter variant — 1-paragraph brief

For quick decisions, drop most of the structure:

```markdown
# Brief: [Question] — YYYY-MM-DD

**Recommendation**: [Option]. [Why, one sentence.]

**Key evidence**: [1–2 specific facts or sources.]

**Risk to flag**: [Top risk, one sentence.]

**Revisit if**: [Trigger.]
```

Works for "we have a 10-min meeting about this tomorrow" situations.

## Long-form variant — strategic research

For multi-week market / competitive / technology research, expand with:

- **Scope**: what's included, what's out of scope.
- **Method**: how the research was done (interviews, public data, benchmarks).
- **Background**: context a reader may not have.
- **Timeline**: how this decision fits with other decisions / deadlines.
- **Appendices**: raw data, full interview transcripts, detailed benchmarks.

Keep the one-page front summary even for long briefs. Execs read the first page only.
