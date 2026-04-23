# Structured output

Parsing free-text LLM output with regex is a bug farm. Every modern provider offers structured output — use it.

## Three mechanisms, one goal

### 1. JSON mode

Forces the model to output valid JSON. Doesn't enforce a schema — just that the output parses.

```python
# OpenAI
response = client.chat.completions.create(
    model="gpt-5",
    response_format={"type": "json_object"},
    messages=[...],
)
```

Use when: you want JSON but the shape varies or is simple enough that you'll handle it in post-processing.

### 2. Structured output with a schema (JSON Schema / Pydantic)

The model's output is constrained to match a schema. Fields guaranteed to exist; types guaranteed to match.

```python
# OpenAI (strict mode)
class Classification(BaseModel):
    label: Literal["bug", "feature", "question"]
    confidence: float
    reason: str

response = client.chat.completions.create(
    model="gpt-5",
    response_format=Classification,
    messages=[...],
)
result: Classification = response.choices[0].message.parsed
```

```python
# Claude (via tools — see below, and check Anthropic's docs for the latest structured output API)
```

Use when: you know exactly what shape you want. This is the default.

### 3. Tool use / function calling

The model "calls" a function with structured arguments. You define the function's parameters; the model fills them in.

```python
# Claude
tools = [
    {
        "name": "classify_ticket",
        "description": "Classify a support ticket.",
        "input_schema": {
            "type": "object",
            "properties": {
                "label": {"type": "string", "enum": ["bug", "feature", "question"]},
                "confidence": {"type": "number", "minimum": 0, "maximum": 1},
                "reason": {"type": "string"}
            },
            "required": ["label", "confidence", "reason"]
        }
    }
]

response = client.messages.create(
    model="claude-opus-4-7",
    tools=tools,
    tool_choice={"type": "tool", "name": "classify_ticket"},
    messages=[...],
)

tool_use = next(b for b in response.content if b.type == "tool_use")
result = tool_use.input
```

Tool use is the most flexible — same API works for one-shot extraction and multi-turn agent loops. When in doubt, use tool use.

## Schema design rules

### Keep schemas small and flat

Deeply nested schemas hurt accuracy. A 3-level nested object with 20 fields produces more errors than three separate 1-level schemas you chain together.

```jsonc
// ❌ Nested and tangled
{
  "ticket": {
    "classification": {
      "category": "bug",
      "subcategory": {
        "area": "ui",
        "severity": {
          "level": "high",
          "justification": "..."
        }
      }
    }
  }
}

// ✅ Flat, even if it repeats some context
{
  "category": "bug",
  "area": "ui",
  "severity_level": "high",
  "severity_justification": "..."
}
```

### Use enums aggressively

```jsonc
{
  "label": {"type": "string", "enum": ["bug", "feature", "question"]}
}
```

Enums make the model pick from a fixed set. This eliminates "BUG", "Bug.", "this is a bug" variants you'd otherwise have to normalize.

### Require fields explicitly

```jsonc
{
  "type": "object",
  "properties": {
    "label": {...},
    "confidence": {...}
  },
  "required": ["label", "confidence"],   // ← don't forget this
  "additionalProperties": false          // ← strict mode
}
```

Without `required`, the model will sometimes skip fields. Without `additionalProperties: false`, the model will sometimes invent extra keys.

### Descriptions matter

```jsonc
{
  "confidence": {
    "type": "number",
    "minimum": 0,
    "maximum": 1,
    "description": "0 = random guess, 0.5 = uncertain, 0.9+ = very sure based on explicit evidence in the input."
  }
}
```

Descriptions are the model's only way to know what a field means. They're prompt material, not decoration. Write them carefully.

## Refusals and fallbacks

Structured output can still fail:
- Model may refuse (safety filter, ambiguous input).
- Network / rate limit errors.
- Model may produce a JSON that parses but is nonsense (enum-correct but wrong).

Handle them:

```python
def classify_safely(text: str) -> Classification | None:
    try:
        response = client.chat.completions.create(...)
        if response.choices[0].finish_reason == "content_filter":
            return None  # refused
        return response.choices[0].message.parsed
    except (ValidationError, RateLimitError) as e:
        log.warning(f"Classification failed: {e}")
        return None
```

For anything user-facing, have a "model unavailable" UX path. Don't assume every call succeeds.

## Don't use structured output for generation tasks

Creative writing, long-form content, explanations — use free text. Forcing these into JSON kills quality. Structured output is for extraction, classification, and tool-call-like tasks.

## Provider differences

- **OpenAI**: `response_format` with a Pydantic model → strict schema, strong guarantees.
- **Anthropic (Claude)**: tool use with `input_schema` → same guarantees, more flexible.
- **Google (Gemini)**: `response_schema` with strict mode.
- **Open models (llama, etc.)**: use a library like `outlines` or `jsonformer` to constrain output at the decoder level.

Check your provider's current docs — this space moves fast.
