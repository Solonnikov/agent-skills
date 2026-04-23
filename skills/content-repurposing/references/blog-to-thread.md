# Blog → Thread

Turn a long-form post into a 5–8-post X/Twitter thread that stands on its own.

## The hook (post 1)

The hook decides whether anyone reads post 2. You have one sentence.

### Formats that work

- **Specific claim**: "We cut p95 latency 60% by replacing 3 lines of code."
- **Counterintuitive take**: "Most Postgres performance problems aren't about indexes."
- **Story opener**: "A year ago, we shipped a feature that almost killed the product. Here's what happened."
- **List promise**: "8 patterns for writing safer git commands. The first one has saved me twice this year."
- **Numeric hook**: "I reviewed 400 PRs last year. Here are the 5 mistakes I caught most often."

### Formats to avoid

- "Thread 🧵" with nothing else. Tells the reader nothing about why to read.
- Vague teases: "You won't believe what I learned..." — clickbait-detected, scrolled past.
- Self-promotion first: "I just wrote a new post! Here's a thread about it." The hook is the post; the self-reference comes later.

### Rules

- Under 260 chars — gives room for "(thread 🧵)" or "(1/8)" if you use those.
- One idea. If two things are fighting for the hook, one is buried in the middle of the thread.
- **No emojis** unless they're load-bearing for the topic.

## The middle (posts 2–7)

Each post = one idea. 1–3 sentences.

### Structure

- **One concrete point per post**, building on the hook.
- **No walls of text**. If a post has 4 sentences, it's probably 2 posts.
- **Use examples, not adjectives**. "Latency dropped 60%" beats "Dramatically improved latency".
- **Break sequential ideas into sequential posts**. Readers scroll; each post gets its own attention.

### Transitions

Avoid explicit "Point 2:" / "Next..." unless the thread is formatted as a numbered list. Most threads flow better with natural topic shifts:

- "The interesting bit:"
- "Which raised a question:"
- "Here's where it gets weird:"
- "The fix:"

### Rhythm

Mix short and long posts. A string of 3 uniformly long posts exhausts the reader; a short post in the middle resets attention.

## The landing (last post)

Close the thread with:

- **A synthesis** — one sentence that wraps the through-line.
- **A CTA** — link to the full post, your newsletter, another piece.
- **An invitation** — "What pattern do you use for X? Curious."

### Example landing

```
These 5 patterns took us from constant fires to 2 incidents a quarter.

Full writeup with code + dashboards → [link]

What's the one thing you've added to your oncall toolkit that actually paid off?
```

## The skeleton

For a 5–8 post thread from a 1,500-word blog post:

```
Post 1: Hook — the single sentence that makes someone care.

Posts 2–3: Context — what's the problem, why does it matter, what did we try first.

Posts 4–6: The meat — the actual insight / pattern / takeaway, with examples.

Post 7: Synthesis — what the reader should walk away with.

Post 8: CTA — link to the full post + an invitation.
```

For shorter posts (500-word source), compress: 4–5 posts total.

## Practical constraints

- **280 chars per post** (or 4,000 if you're on X Premium — but audiences read shorter posts more).
- **No more than 9 posts** usually. Longer threads lose readers.
- **Embed images / screenshots** for posts that benefit (code snippets, charts). They dramatically increase engagement.
- **The first two posts are visible in the preview card** when someone shares the thread. Make them both strong.

## Common mistakes

- **Copy-pasting paragraphs** from the blog. Tone doesn't fit; rhythm is off.
- **Burying the thesis in post 5**. If they didn't scroll to post 2, they never will.
- **Every post is a fragment**. Threads can be conversational, but they need to be readable — full sentences, landed thoughts.
- **Every post ends with "..."**. Manipulative and obvious. End each post cleanly; let the next one carry its own weight.
- **Over-hashtagging**. X has low hashtag tolerance. One or two relevant ones is fine; five makes you look like a bot.

## Tools

- Post the thread natively in the X client. Third-party schedulers sometimes format threads weirdly.
- Draft the thread in a plain-text editor first; paste into X when ready. X's composer eats drafts if you navigate away.
