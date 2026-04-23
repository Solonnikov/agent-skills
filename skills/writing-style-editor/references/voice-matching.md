# Voice matching

When the user wants the edit to sound like them — or like someone else — you need to extract the voice from a sample, then mirror it.

## Extract the voice

From a sample of the target's writing, extract these signals:

### Sentence length

- Median and range. Short (5–10 words), medium (10–20), long (20+).
- Pattern: mostly short? Mostly mixed? Long monologues broken by one-word sentences?

### Opening style

- Does the writer start with a hook? A question? A declarative? A contrarian take?
- Do they set context first, or dive straight in?

### Word choice

- Formal ("utilize", "endeavor", "demonstrate") vs casual ("use", "try", "show").
- Jargon present? Industry-specific terms used without explanation?
- Strong verbs or gentle ones?

### Voice tics

- Specific phrases the writer reuses. Copy them — they're often a load-bearing signal of voice.
- Rhetorical moves: "Here's the thing..." "So...", "Anyway,". Idiosyncratic but human.
- Digressions in parens, or focused sentences? Em-dashes, or commas?

### Humor / tone

- Dry, ironic, self-deprecating, earnest, deadpan, warm?
- Does the writer risk a joke, or keep it serious?

### Structure

- Short paragraphs (1–3 sentences) or long ones?
- Lists or flowing prose?
- Headers or none?

### Relationship to the reader

- Distant ("the reader", "users", "one might...") or close ("you", "we")?
- Authoritative or exploring-together?

## Mirror, don't imitate

**Mirror**: use the same sentence-length rhythm, word register, and structural preferences.

**Don't imitate**: don't copy the writer's signature phrases verbatim, don't fake their humor if you don't have enough sample, don't pretend to share their opinions.

Good mirroring reads as *their voice saying something new*. Bad mirroring reads as *you pretending to be them*.

## Common voice archetypes

Rough sketches — use these as starting points, then match the specific writer.

### "Founder casual"

- Short, declarative sentences.
- Some fragments for emphasis.
- "We" / "you" direct address.
- Light humor, self-aware.
- Drops in a concrete number or example per paragraph.
- No emojis, no LinkedIn-speak.

```
We shipped. It's 40% faster. Here's what changed and why it matters.
```

### "Technical peer"

- Medium sentences, varied.
- Precise nouns and verbs.
- Assumes reader knows the domain.
- No hype words, no adjectives that don't earn their place.
- Code samples or specific file paths for concreteness.

```
Moved auth validation from middleware to the router layer. Latency on /profile dropped ~12ms p95. Trade-off: each route now calls into the auth module explicitly.
```

### "Newsletter warm"

- Varied sentence length; longer paragraphs.
- More "you" than "I".
- Signposts: "Here's the thing...", "Which brings me to..."
- Personal touches — story, example, anecdote.
- Ends with a one-sentence takeaway.

### "Academic / professional"

- Long sentences with subordinate clauses.
- Hedges ("suggests", "indicates", "may") used deliberately.
- Passive voice acceptable for emphasis on object.
- Citations and data woven in.

### "Hemingway"

- Short sentences. Declarative.
- Minimal adjectives. Concrete nouns.
- No throat-clearing. No hedges.
- Lets the facts do the work.

## When the sample is small

If you only have a paragraph or two, match what you *can* see — sentence length, register, tics — and ask the user to flag anything that doesn't sound like them. Iterate.

## When there's no sample

Default to "clear, human, no ornament":

- Varied sentence length.
- Active voice.
- Concrete nouns.
- No hype words.
- No emojis (unless explicitly requested).
- Medium-formal — "the reader isn't your boss, isn't your friend".

Then ask for feedback; tighten from there.
