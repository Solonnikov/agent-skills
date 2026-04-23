# Synthesis patterns

The gap between "notes from research" and "a brief" is synthesis. This is where most briefs fail.

## The first move: extract claims

From raw notes, pull specific, atomic claims. A claim is:

- One sentence.
- Asserts something specific.
- Attributable to a source.

```
Raw: "The Notion blog says Postgres was a better fit because their data was relational
and their team had prior experience with it, which made onboarding faster."

Extracted:
  C1: Notion chose Postgres over MongoDB for their relational workload. [Notion blog]
  C2: Notion's team had prior Postgres experience. [Notion blog]
  C3: Notion reports faster onboarding as a result. [Notion blog]
```

Three atomic claims are easier to synthesize than one long paragraph.

## Cluster claims by theme

Group related claims. In a typical brief, clusters are:

- **Evidence for Option A**
- **Evidence for Option B**
- **Known tradeoffs**
- **Operational considerations**
- **Cost considerations**

Place each claim under the most relevant cluster. A claim might appear in two clusters if it's load-bearing for both.

## Look for agreement and contradiction

Within a cluster:

- **Agreement**: multiple independent sources say similar things. Strengthens confidence.
- **Contradiction**: sources disagree. Investigate: different scope? different date? different bias?
- **Silence**: everyone avoids a topic. Often means it's not well-measured. Flag as a gap.

Write it up:

```
Strong evidence: 3 independent sources (Notion, company X, academic paper Y) all report that
Postgres scales vertically well to our projected load.

Disagreement: vendor blog claims MongoDB is 5x faster at writes; independent benchmark from
2024 shows them comparable on our workload profile. Likely the vendor comparison used a
write-heavy synthetic benchmark not representative of our use case.
```

## Find the gaps

Ask: what did you want to know that you couldn't find?

- "I couldn't find production benchmarks at our specific scale."
- "No source addressed the cost of team training on MongoDB."
- "The latest data I could find is from 2024; there was a major version bump in 2025 that might change the picture."

Gaps are not a weakness of the brief — they are part of the brief. Hiding them is.

## Connect evidence to the recommendation

Every recommendation bullet should cite specific evidence. This is the synthesis work:

```
Weak:
- Postgres is the better choice.

Better:
- Postgres is the better choice. Our workload is relational; our team knows Postgres.

Strong:
- Postgres is the better choice because:
  - 90% of query patterns are relational [Internal discussion 2026-04-21].
  - Team has 5 Postgres engineers vs 0 MongoDB [HR roster].
  - JSONB handles the one semi-structured field we need [PG docs + Notion blog].
```

Each reason is grounded; each reason is attributable.

## Steel-man the alternatives

Before recommending, state the best case for each option you rejected:

```
MongoDB's strongest case: schema flexibility for unpredictable user attributes; proven at
massive scale; mature horizontal scaling. Why we rejected: our use case is 90% relational,
team unfamiliarity means 4–6 weeks of onboarding.
```

This serves two purposes:

1. Shows the reader you understood the alternative, not a strawman of it.
2. If the reader's default was MongoDB, they can see their reasoning addressed and either agree with your counter or push back specifically.

## Stating confidence

Beyond the recommendation, state how sure you are:

- **High** — multiple independent sources agree; low bias in the evidence; the recommendation would surprise few experts.
- **Medium** — evidence leans one way but not overwhelming; reasonable experts might choose differently.
- **Low** — limited evidence or significant gaps; recommend, but flag that more research would help.

Example phrasing:

```
Recommendation: Use Postgres (high confidence).
Recommendation: Use Postgres (medium confidence — benchmarks at our scale not confirmed).
Recommendation: Use Postgres (low confidence — primary evidence is second-hand; run a 2-week
spike before committing).
```

Low-confidence recommendations are not failures. They're honest.

## The "trigger to revisit" trick

The best briefs include a specific trigger that would cause re-evaluation:

```
Revisit if:
- User attributes grow beyond 20 fields (re-evaluate MongoDB's flexibility case).
- Team hires a MongoDB specialist (removes onboarding cost).
- Postgres JSONB performance at 10M rows turns out worse than expected during spike.
```

This turns a static recommendation into a living one. Six months later, someone can check the triggers and know whether to re-research or stay the course.

## Anti-patterns

### Listing without synthesizing

```
BAD:
- Source A says X.
- Source B says Y.
- Source C says Z.

Recommendation: do something.
```

That's a reading list, not a brief. Synthesize.

### Recommendation not tied to evidence

```
BAD:
- Evidence supports approach X.
- Approach Y has drawbacks.

Recommendation: approach Y.
```

Why? Either the evidence was misread, or there's unstated reasoning — either way, the reader is confused.

### False certainty

Writing like everything is known, when half your sources were inconclusive, trains readers to distrust future briefs. High confidence is earned; med / low is honest.

### Burying disagreement

Pretending sources agreed when they didn't. Always backfires in review.

## When the synthesis reveals no good answer

Sometimes the research genuinely suggests "it depends" or "all options have serious downsides." That's a legitimate outcome. The brief becomes:

```
Recommendation: I don't have a strong recommendation. Here's why, and here's what would
resolve it.
```

Followed by the specific question / experiment / spike that would get to an answer. That's still a useful brief — it prevents the reader from committing on bad data and tells them what to do next.
