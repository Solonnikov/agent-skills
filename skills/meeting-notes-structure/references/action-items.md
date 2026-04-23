# Action items

Action items are the reason most meetings exist. Get them right; forgive the rest.

## Format

```
| Owner | Task | Due |
|-------|------|-----|
| @alice | Draft the RFC for the auth rewrite | 2026-05-01 |
```

Three fields, always. Missing any one = the task won't get done.

## The three fields

### Owner — exactly one

- **Always one person**, even if multiple will help. Shared ownership means no ownership.
- Use the person's handle (`@alice`) or full name, not a role ("the PM", "engineering").
- If the owner isn't in the room, flag it: "⚠️ @dana not at meeting — confirm before executing."
- If the right owner is genuinely unclear, assign the most senior person in the room to assign it offline.

### Task — specific and verb-first

Bad: "Look into the pipeline issue."
Good: "Identify the p95 latency source in the auth pipeline and post findings by Friday."

Bad: "Dark mode."
Good: "Ship dark mode toggle in settings for beta users."

Tests:
- Starts with an action verb (draft, write, investigate, ship, review, decide, confirm).
- Specific enough that two people would agree it's done or not done.
- Scope is one person's work, not a project's.

### Due — a date, not a vibe

- `2026-05-01` beats "next week".
- "EOW" (end of week) is fine for low-stakes; actual date for anything that matters.
- No deadline = no urgency = doesn't happen.

If the task is genuinely ambiguous on timing, set a "by when do we check in?" date instead: "Re-evaluate by 2026-04-30."

## What NOT to do

### "The team will..."

No team has ever done anything. Individuals do things. Name one.

### "We should probably..."

If you're noting it, it's an action item. If it's an action item, it needs an owner and a date. If it doesn't have those, it's just "discussed something, went home."

### "Alice to think about X"

"Think about" isn't a task. What output does the thinking produce? "Alice to write a one-page summary of trade-offs by Friday" is a task.

### "Follow up" with no date

"Alice to follow up." Follow up on what? When? Shorten: "Alice to send the contract draft to Priya by Wednesday."

## Writing action items during the meeting

Capture immediately — don't let them get lost in the discussion. If someone says "I'll handle the legal review," interrupt: "By when? — writing it down."

This feels pushy the first few times. It's worth it. Decisions without owners fade; decisions with owners + dates ship.

## Closing the loop

- **In the notes**: list every action item at the top.
- **After the meeting**: DM each owner their specific action item (Slack / email). Short: "From today's meeting — you own X, due Y. Here's the notes: [link]."
- **Next meeting**: review the previous meeting's action items first. "Done / in progress / blocked / dropped."
- **Dropped is fine**. If an action item isn't going to happen, kill it explicitly. Zombie action items rot the doc.

## Red flags

- **No action items.** The meeting didn't decide anything. Ask: was this the right meeting? Should it have been an email?
- **Everyone owns the same thing.** "We'll all review and send feedback" = no one sends feedback. Name one person to collect.
- **Same action item appearing for 3 meetings in a row.** Something is blocking it. Call it out explicitly; either unblock or drop.
- **Action items without any decisions.** The meeting was action-focused but didn't decide anything underlying. Usually a sign of avoidance.

## One-line rule for emergencies

If you only capture one thing from a meeting, capture this:

**Who owes what to whom by when.**

If you have that, the meeting produced output. If you don't, it didn't — and that's worth noticing.
