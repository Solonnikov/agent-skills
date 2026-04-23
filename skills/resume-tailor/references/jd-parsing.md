# Parsing a JD

Most job descriptions follow a pattern. Learn the pattern, you can extract what actually matters in 60 seconds.

## The structure of a typical JD

1. **Company / role intro** — often skippable; sometimes has signals about culture.
2. **"What you'll do" / "Responsibilities"** — what they want the person to do.
3. **"What we're looking for" / "Requirements"** — the person's profile.
4. **"Nice to have" / "Bonus"** — softening the requirements.
5. **Benefits / compensation** — usually not what you're tailoring against.

Focus on #2 and #3. #4 is a bonus; #1 and #5 rarely drive the match.

## Extract must-haves vs nice-to-haves

### Must-haves

Signals:
- "Required" / "Must have" / "Minimum qualifications".
- Listed first, in bold, or in their own section.
- Specific: "5+ years of X", "proficient in Y", "experience with Z".
- Repeated in the responsibilities (if they mention it twice, it's core).

### Nice-to-haves

Signals:
- "Preferred" / "Bonus" / "Plus if".
- Softer language: "exposure to", "familiar with", "interest in".
- Often a separate section at the end.

### Example — extraction

Raw JD snippet:

> "We're looking for a senior backend engineer with 5+ years of experience in Go or Rust, strong familiarity with distributed systems, and a track record of shipping production code. Experience with AWS is required. Bonus: Kubernetes, open source contributions, or startup experience."

Extracted:
- **Must-have**: 5+ years Go/Rust, distributed systems, shipped production code, AWS.
- **Nice-to-have**: Kubernetes, OSS, startup experience.
- **Hidden signals**: "track record of shipping" — they want evidence of completion, not just attempts. "strong familiarity" with distributed systems — they'll probe in interviews.

## Extract culture signals

Throwaway phrases carry real meaning. Don't ignore them.

| Phrase | Likely means |
|--------|--------------|
| "Fast-paced" | Long hours or limited process. |
| "Wear many hats" | Small team; you'll do things outside your JD. |
| "Ownership mindset" | They want you self-directed; no PM holding your hand. |
| "Collaborative" | Lots of meetings. |
| "Data-driven" | Decisions via metrics; be ready for Excel / SQL tasks. |
| "Customer-obsessed" | Customer support / feedback is part of the role. |
| "Build from scratch" | Greenfield — no legacy code, but also no existing infra. |
| "Mature codebase" | Legacy — prepare for tech debt. |
| "Cross-functional" | You'll interact with sales, marketing, finance. |
| "Strategic thinker" | Exec track or PM-adjacent work. |
| "High-growth environment" | You'll wear multiple hats; expect churn. |

Use these to decide whether the role is a fit and to pre-empt behavioral interview questions.

## Keyword extraction for matching

Make a list of the specific terms used in the JD. When tailoring:

- If the user's résumé uses a different term for the same thing, **align to the JD's term** (if still truthful).
  - "worked with customers" → "partnered with customers" if JD says partner.
  - "Python scripts" → "Python services" if JD says services.
- If the résumé already uses the JD's term, make it more prominent (earlier bullet, bold, or pull up to a summary section).

Don't:
- Stuff keywords nonsensically. ATS parsers are OK; humans will notice.
- Claim a skill not on the résumé. Adding "Kubernetes" because the JD mentions it, when you've never touched Kubernetes, will fail in the interview.

## What the JD tells you about the interview

- **Required technologies** → you'll likely be tested on them. Brush up.
- **"Design" / "architecture"** → expect a system-design round.
- **"Communicate" / "present" / "stakeholder"** → a behavioral round about cross-functional work.
- **"Mentorship" / "lead"** → they're evaluating leadership potential; expect "tell me about a time you..." questions.
- **Specific team names** (search engine team, billing team, platform team) → research the team's tech blog or conference talks.

## Prioritize when tailoring

Not every bullet on the résumé needs to match the JD. Aim for:

- **Top of each role**: the 2–3 bullets most aligned with the JD's must-haves.
- **Middle**: supporting evidence, nice-to-haves.
- **Bottom (or cut)**: unrelated work. Recruiter will skim or skip.

Within the same company, reorder bullets so that the strongest match is the first one they read.

## When the JD is vague

Some JDs are two sentences. In that case:

- Match what's explicit.
- Research the company's engineering blog / recent roles / Glassdoor to infer emphasis.
- If nothing's inferrable, prioritize versatility: breadth bullets over depth ones.
- Call the recruiter if in doubt — "could you share more on what the day-to-day looks like?"
