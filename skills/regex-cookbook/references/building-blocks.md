# Building blocks

Primitives to compose new patterns. Know these cold; you'll write most regex from memory.

## Anchors

| Anchor | Matches |
|--------|---------|
| `^` | Start of string (or line, with `m` flag) |
| `$` | End of string (or line, with `m` flag) |
| `\b` | Word boundary — between a `\w` and a non-`\w` char |
| `\B` | Non-word-boundary |
| `\A` | Start of string (always, ignores `m` flag) — Python/PCRE/.NET, not JS |
| `\z` | End of string (always) — Python/PCRE/.NET, not JS |

Use `\b` for matching whole words: `\bcat\b` matches `cat` but not `category` or `scat`.

## Character classes

| Class | Matches |
|-------|---------|
| `.` | Any character except newline (add `s` flag to include newlines) |
| `\d` | Digit `[0-9]` (or Unicode digits with `u` flag) |
| `\D` | Non-digit |
| `\w` | Word char — `[A-Za-z0-9_]` |
| `\W` | Non-word |
| `\s` | Whitespace — space, tab, newline, carriage return |
| `\S` | Non-whitespace |
| `[abc]` | One of `a`, `b`, `c` |
| `[^abc]` | Not `a`, `b`, `c` |
| `[a-z]` | Range |
| `[a-zA-Z0-9_-]` | Combined |

Inside a character class, most metacharacters lose their magic. `[.*+?]` matches those literal chars; outside, `.*+?` are special.

## Quantifiers

| Quantifier | Matches |
|------------|---------|
| `*` | 0 or more |
| `+` | 1 or more |
| `?` | 0 or 1 (optional) |
| `{n}` | Exactly n |
| `{n,}` | n or more |
| `{n,m}` | Between n and m |

### Greedy vs lazy

Quantifiers are **greedy** by default — they match as much as possible. Append `?` to make them lazy (match as little as possible):

```regex
".*"         # greedy — matches "hello" and "world" together in "hello" and "world"
".*?"        # lazy — matches "hello" and "world" separately
```

Lazy is what you want for "match everything between two delimiters."

### Possessive and atomic groups

Some flavors (PCRE, Java, Python 3.11+) support possessive (`*+`, `++`, `?+`) and atomic (`(?>...)`) groups that don't backtrack. They prevent ReDoS on specific patterns but aren't available in JavaScript.

## Groups

| Construct | Meaning |
|-----------|---------|
| `(abc)` | Capturing group — use for extraction |
| `(?:abc)` | Non-capturing group — use for structure without capture |
| `(?<name>abc)` | Named group — reference as `\k<name>` or result `.name` |
| `(?=abc)` | Positive lookahead — "followed by abc" (doesn't consume) |
| `(?!abc)` | Negative lookahead — "not followed by abc" |
| `(?<=abc)` | Positive lookbehind — "preceded by abc" |
| `(?<!abc)` | Negative lookbehind — "not preceded by abc" |

Use non-capturing `(?:...)` unless you actually need the capture. It's cheaper and doesn't pollute your match result's numbered groups.

### Lookaround examples

```regex
(?<=\$)\d+           # digits preceded by $ (matches 42 in $42, not in 42)
\d+(?= dollars)      # digits followed by " dollars"
(?<!not )interested  # "interested" not preceded by "not "
```

Lookaround is zero-width — it checks the surrounding context without consuming characters. Useful for extraction when you don't want the delimiter in the match.

## Alternation

```regex
cat|dog|fish         # cat, dog, or fish
(cat|dog|fish)s?     # optionally plural
```

Alternation is expensive — put the most common option first and anchor what you can.

## Backreferences

Refer back to a captured group later in the same pattern:

```regex
<(\w+)>.*?</\1>       # <tag>...</tag>
(\w+)\s+\1            # any word repeated, separated by whitespace
```

Regex with backreferences can't be matched with a linear-time engine. If you need Go's RE2, rewrite without backreferences.

## Flags (modifiers)

| Flag | Meaning |
|------|---------|
| `i` | Case-insensitive |
| `m` | Multiline — `^` and `$` match line boundaries |
| `s` | Dotall — `.` matches newlines |
| `g` | Global — match all occurrences (JS, PCRE) |
| `u` | Unicode — `\d`, `\w`, `\s` match Unicode chars |
| `x` | Extended — allow whitespace and comments in the pattern (not JS) |

JS syntax: `/pattern/gims`
Python: `re.compile(r'pattern', re.MULTILINE | re.IGNORECASE)`

### Extended mode — write readable regex

Python/PCRE/.NET support `x` mode. You can format a complex regex across lines with comments:

```python
re.compile(r"""
    ^
    (?P<year>\d{4})   # year
    -
    (?P<month>\d{2})  # month
    -
    (?P<day>\d{2})    # day
    $
""", re.VERBOSE)
```

Saves sanity on 200-character patterns. Not available in JavaScript.

## Common compositions

### "Optional segment"

```regex
foo(bar)?baz          # matches foobaz or foobarbaz
```

### "One or more, separated by"

```regex
\w+(,\s*\w+)*         # word, optionally followed by ",word",",word",...
```

### "Between delimiters"

```regex
\[([^\]]*)\]          # [anything except ]]
"([^"]*)"             # "anything except ""
```

### "Starts with" / "ends with"

```regex
^foo                  # starts with foo
foo$                  # ends with foo
^foo$                 # exactly foo
```
