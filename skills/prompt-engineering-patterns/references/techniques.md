# Techniques that move accuracy

Not all prompting "tricks" actually help. Some help in academic benchmarks but hurt in production (more latency, more cost, more variance). Here's what empirically works, in roughly the order you'd reach for it.

## Few-shot examples — the highest-leverage technique

Adding 2–5 examples of input-output pairs is usually the single biggest accuracy improvement.

```
<examples>
<example>
<input>The app crashes when I click Save on a form with 100+ fields.</input>
<output>bug</output>
</example>
<example>
<input>Can you add dark mode?</input>
<output>feature</output>
</example>
<example>
<input>How do I reset my password?</input>
<output>question</output>
</example>
</examples>
```

Rules:
- **Quality over quantity.** Five clean, diverse examples beat twenty noisy ones.
- **Cover the edge cases.** If the model fails on sarcasm, include a sarcastic example.
- **Keep format identical** across examples. The model will mimic the exact shape you show, including whitespace.
- **Order matters.** Put the most "typical" example first, and one counterexample or tricky case near the end.

When few-shot hurts: if the task is genuinely novel and examples bias the model toward superficial patterns. If 3 examples are worse than 0, the examples are wrong.

## Chain-of-thought (CoT)

Ask the model to think step by step before answering. Helps on reasoning, math, multi-hop classification, anything where the right answer requires intermediate steps.

```
Before answering, reason step by step in <reasoning> tags.
Then give the final answer in <answer> tags.
```

Output shape:

```
<reasoning>
The ticket mentions a crash ("crashes when I click Save"). That's an existing feature failing.
It also specifies a reproducible condition ("with 100+ fields"). This is a bug report.
</reasoning>
<answer>bug</answer>
```

Tradeoffs:
- **Improves** accuracy on reasoning-heavy tasks.
- **Adds latency** proportional to the reasoning length.
- **Adds cost** — reasoning tokens are output tokens.
- **Do not use** for simple classification or extraction where the answer is one lookup away.

For frontier models (Claude Opus/Sonnet 4.x with extended thinking, GPT-5.x reasoning), the model does this internally — you don't need to prompt for it. Check whether your model has native reasoning and use that instead.

## Prompt chaining

Break one complex prompt into a sequence of simpler ones. Each prompt does one job; its output feeds the next.

```
Prompt 1: Extract the 3 most important entities from this document.
  → list of entities
Prompt 2: For each entity, classify its type (person / org / location).
  → list of typed entities
Prompt 3: Generate a summary mentioning each entity by type.
  → final output
```

When chaining helps:
- Each step is simpler and more reliable than the monolithic prompt.
- You can measure and fix each step independently.
- Different steps can use different models (a small model for extraction, a bigger one for generation).

When chaining hurts:
- Errors compound — if each step is 95% accurate, a 3-step chain is only ~86% accurate end-to-end.
- Latency is cumulative.
- Cost is cumulative.

Use chaining when the task has genuinely distinct sub-tasks. Don't use it as a substitute for one good prompt.

## Self-consistency (sampling)

Run the same prompt N times at non-zero temperature, take the majority answer. Useful for reasoning tasks where the model sometimes gets it right and sometimes doesn't.

```python
answers = [call_model(prompt, temperature=0.7) for _ in range(5)]
final = most_common(answers)
```

Reality check: this is 5x the cost for a modest accuracy bump. Only worth it on high-stakes tasks where the improvement justifies it — and even then, a better prompt usually beats sampling.

## Structured reasoning — scratchpads

For multi-step tasks, give the model an explicit scratchpad to use:

```
<scratchpad>
Step 1: Identify all dates in the input.
Step 2: For each date, determine if it's past, present, or future relative to 2026-04-23.
Step 3: Filter to only future dates.
Step 4: Return the filtered list.
</scratchpad>
```

The model uses the scratchpad as a reasoning space. Output quality is higher because the model "shows its work" in a designated area rather than mixing reasoning and answer.

## Persona / role assignment

"You are a senior tax accountant" — this sometimes helps and sometimes doesn't. What works:

- **Specific expertise framing** when the task benefits from narrow domain knowledge.
- **Output-style framing** ("You are a technical writer who favors concise, neutral prose").

What doesn't work:

- Generic "You are a helpful assistant" — the model already is.
- "You are the world's greatest…" — flattery doesn't unlock capability.
- "You are an expert who never makes mistakes" — this creates overconfidence.

## What does NOT help (usually)

- **"Take a deep breath and think step by step"** — worked on older GPT, essentially no effect on frontier models.
- **"Your job depends on this"** — cute, doesn't move accuracy.
- **"You will be tipped $100 for a correct answer"** — same.
- **"Don't hallucinate"** — the model has no mechanism to comply. Ground with sources instead.
- **Excessive capitalization** ("YOU MUST RETURN JSON") — one emphatic instruction works; five don't.

Save tokens for structure, examples, and explicit output format. That's where accuracy lives.
