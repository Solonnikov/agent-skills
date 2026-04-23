# Prompt caching

Prompt caching stores the output of the model processing the prompt's static prefix and reuses it on subsequent calls. This is the single biggest cost and latency win available in production LLM apps.

## Why it matters

For a typical RAG or agent workload:

| Metric | Without caching | With caching |
|--------|-----------------|--------------|
| Latency (time to first token) | ~2–4s for long prompts | ~200–500ms |
| Cost per call | 100% | 10–25% (varies by provider) |

Both Anthropic and OpenAI offer caching. The mechanism and pricing differ, but the structural rule is the same: **put stable content first, variable content last.**

## How it works — at a glance

1. You mark a boundary in your prompt (or the provider auto-detects).
2. On the first call, the model processes the whole prompt; the KV cache for everything up to the boundary is stored, indexed by an exact hash of the prefix.
3. On subsequent calls with the same prefix, the cached KV is reused. The model only processes what comes after the boundary.

Key word: **exact.** Any change to the cached prefix — a space, a newline, a version number — invalidates the cache.

## Anthropic (Claude)

Claude uses explicit cache control blocks:

```python
response = client.messages.create(
    model="claude-opus-4-7",
    system=[
        {
            "type": "text",
            "text": LARGE_STABLE_SYSTEM_PROMPT,
            "cache_control": {"type": "ephemeral"},
        }
    ],
    messages=[
        {"role": "user", "content": user_query}  # variable, not cached
    ],
)
```

- Up to 4 cache breakpoints per prompt.
- Minimum cacheable: 1024 tokens for Sonnet, 2048 for Haiku, 1024 for Opus.
- Cache TTL: 5 minutes (ephemeral) or 1 hour (extended).
- **Pricing**: cache writes cost more than normal tokens; cache reads cost ~10% of normal. Break-even is usually at 2+ reads within the TTL.

For agent loops (multi-turn conversations), cache the system prompt + tool definitions + early conversation history. The cache grows with each turn and each assistant message up to a breakpoint is cacheable.

## OpenAI (GPT)

OpenAI's caching is automatic — no API flag needed:

- Prompts longer than 1024 tokens are eligible.
- The system caches the prompt prefix in 128-token increments.
- Cache hits reduce input token cost by 50% and latency by up to 80%.
- No TTL controls — OpenAI manages cache eviction.

The application-level rule is the same as Claude: put stable content at the start.

## How to structure for cache hits

### The ideal layout

```
[ STABLE PREFIX — cache this ]
- System prompt / persona
- Tool definitions / function schemas
- Few-shot examples
- Large static context (codebase summaries, doc corpora, policy text)

[ VARIABLE SUFFIX — not cached ]
- Current user input
- Session-specific data (timestamps, session IDs)
- Retrieved documents (if they change per call — though see below)
```

### RAG-specific cache patterns

For RAG, retrieved documents change per query, so putting them at the end avoids invalidating the cache. But if you're searching a small corpus and the same documents come back often, consider:

```
[ CACHED ]
- System prompt
- All documents in the corpus, each labeled

[ NOT CACHED ]
- The query + instruction: "Based ONLY on document IDs <list>, answer…"
```

The retrieval step narrows by ID reference instead of document content — the full corpus stays cached, retrieval is effectively pointer-passing.

### Agent loop cache patterns

```
Turn 1:
  [Cached: system + tools]
  [New: user query]
  → model emits tool_use

Turn 2:
  [Cached: system + tools + user query + tool_use]
  [New: tool_result]
  → model emits next step
```

Each turn extends the cached portion. Mark the last stable message as the cache breakpoint.

## Pitfalls that destroy cache hits

- **Injecting timestamps** into the system prompt: `"The current time is 2026-04-23T15:42:11Z"`. Every call invalidates the cache. Put time in the user message or fetch it via a tool.
- **Jitter in tool descriptions**: rebuilding tool schemas from random iteration order. Always serialize tools in a stable order.
- **Version strings that update on every deploy**: `"You are running version 1.2.34-build-789"`. Drop the build number.
- **Slightly different whitespace** between calls — tabs vs spaces, trailing newlines, different indentation levels. Normalize once before sending.
- **User-specific info in the system prompt**: `"The user's name is {name}"`. If names rotate, you never hit cache. Move personalization to the user turn.

## Measuring cache effectiveness

The response object tells you cache activity:

```python
# Anthropic
usage = response.usage
print(usage.cache_creation_input_tokens)  # billed at write price (higher)
print(usage.cache_read_input_tokens)      # billed at read price (lower)
print(usage.input_tokens)                  # non-cached input tokens

# OpenAI
print(response.usage.prompt_tokens_details.cached_tokens)
```

Track `cache_read / (cache_read + input_tokens)` as your hit rate. Production apps should see 80%+.

## When not to cache

- The prompt is shorter than the minimum cacheable size (1024–2048 tokens).
- The prompt changes every call (one-off summaries, per-user template expansion).
- Traffic is so low that cached entries expire before reuse.

If your prompt is under 1k tokens, focus on structure and examples; caching adds complexity for no benefit.
