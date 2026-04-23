# Source evaluation

Not all sources are equal. A tweet about a research paper is not the research paper.

## The credibility hierarchy

Rough, in priority order:

1. **Primary sources** — original data, official documentation, the thing itself. "Anthropic's documentation" for Claude questions, not "a blog post about Claude's documentation."
2. **Expert secondary sources** — peer-reviewed papers, technical books, documentation from the actual maintainers, conference talks from the team who built it.
3. **Analyst reports / industry research** — Gartner, Forrester, credible trade publications. Useful for aggregate trends; be aware of vendor-paid reports.
4. **Journalistic coverage** — reputable tech press, major publications. Good for context; bad for technical depth.
5. **Blog posts / tutorials** — helpful for "how do I do this" but variable quality. Source the blog post's sources.
6. **Social media** — mostly opinion. Useful for surfacing new tools / issues; never as sole evidence.
7. **Marketing content** — vendor's own blog posts, whitepapers, sales decks. Assume bias.
8. **LLM output** — including from Claude. Treat as a starting point, verify via above sources.

Cite from the highest credible level you can.

## The five credibility questions

For any source, ask:

### 1. Who's the author / org?

- Specific humans with track records > anonymous / pseudonymous.
- Org reputation: is the publication known for rigor or clickbait?
- Author's domain: someone writing about their own specialty is more credible than a generalist.

### 2. What's their incentive?

- Vendor blog promoting vendor's product → conflict of interest.
- Consultant selling services in the space → motivated to talk up complexity.
- Academic researcher → motivated by career / citation; honest but sometimes removed from practice.
- Competitor → motivated to downplay the subject.

Not necessarily disqualifying — but flag the bias when citing.

### 3. When was it written?

- Fast-moving fields (AI, Web3, JS ecosystem) rot within 6–18 months.
- Foundational concepts (database design, OS internals) stay relevant for years.
- Flag date in the citation: "As of 2026-04-23" or "Written November 2024."

### 4. What evidence do they offer?

- Primary data, benchmarks, source code links, concrete examples → strong.
- Appeals to authority ("industry experts agree") → weak.
- Unsourced statistics → very weak ("70% of companies" — which 70%? How measured?).

### 5. Does it agree with other credible sources?

- Independent corroboration increases confidence.
- Lone source making surprising claim → suspicious until corroborated.
- Everyone citing the same source → not independent, could be a telephone game.

## Red flags

Skip or heavily discount sources with:

- **No author listed** (SEO content farms).
- **Generic titles with "best" / "top" / "ultimate"** and no author expertise visible.
- **Publication date missing or hidden.**
- **Extensive lists with shallow content** (affiliate-revenue pattern).
- **Vague sources**: "Studies show...", "Experts say...", without naming them.
- **Excessive ads / paywalls blocking the content itself.**
- **AI-generated content** with no editorial oversight — getting harder to spot; look for AI tells (uniform sentence length, "in today's landscape", inconsistent specifics).
- **Old framework docs** without a "deprecated" banner.

## Bias checklist

Every source has some bias. Name it.

- **Vendor** — selling a product; pros overstated.
- **Competitor** — downplaying a product; cons overstated.
- **Consultant** — selling expertise in a thing; making it sound complex.
- **Academic** — optimizing for novelty / publication; solutions may be impractical.
- **Maintainer** — protective of decisions already made; reluctant to admit tradeoffs.
- **Former maintainer** — may be bitter or nostalgic; watch both directions.
- **Early adopter** — honeymoon phase; limitations not yet surfaced.
- **Late adopter** — skepticism; may miss upside.
- **Generalist tech press** — optimizing for engagement; depth sacrificed.

Citing doesn't require agreeing. You can quote a biased source and flag the bias: "[vendor] claims 10x performance [source]; note this is their own benchmark."

## Handling contradiction

When sources disagree:

1. **Check recency** — is one newer? Old source may be outdated.
2. **Check scope** — are they measuring the same thing? "Performance" in Postgres vs MongoDB may mean different workloads.
3. **Check bias** — vendor vs competitor disagreement is expected; not useful signal.
4. **Check methodology** — benchmarks with different hardware aren't comparable.
5. **Name the disagreement in the brief** — "Source A claims X, Source B claims Y; I couldn't reconcile the difference. Likely driven by [hypothesis]."

Don't pretend the disagreement doesn't exist. Reviewers will notice.

## Citing in the brief

Format that works:

```
- [Source title] — [author or org] — [link] — [credibility note].
```

Example:

```
- "Why we chose Postgres over MongoDB" — Notion Engineering blog, 2023-11 — [link] — vendor blog; they chose Postgres for a similar workload, so useful anchor point.
- "MongoDB at scale" — MongoDB-sponsored whitepaper, 2025 — [link] — vendor marketing; extract numbers but treat as ceiling rather than expected.
```

The credibility note in the citation does the work of disclosing bias + situating the source.

## When you can't find authoritative sources

Say so.

> "I couldn't find an authoritative comparison of X vs Y under our specific load profile. Recommendation is based on first-principles analysis and second-hand reports. Benchmarking in a sandbox is required before commit."

This is a legitimate conclusion. "I don't know yet; here's how to find out" beats fake certainty.
