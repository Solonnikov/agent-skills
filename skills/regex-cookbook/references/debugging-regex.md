# Debugging regex

## Test at regex101.com — always

[regex101.com](https://regex101.com/) is the definitive regex tester. What to do:

1. **Pick the right flavor** in the left sidebar (JS / Python / PCRE / Go / .NET).
2. **Paste the pattern** in the top field.
3. **Paste real input** — from logs, from test cases, from production — in the test field.
4. **Click on the pattern tokens** on the right to see explanations. The "Explanation" panel translates the regex into English.

Don't eyeball regex. The dev tools show why it's or isn't matching.

## "It's not matching what I expect"

### Check anchoring

```regex
^foo$            # exactly "foo"
^foo             # starts with "foo"
foo              # contains "foo" anywhere
\bfoo\b          # "foo" as a whole word
```

Missing `^`/`$` is the #1 cause of "why does this regex accept garbage?"

### Check escaping

`.` matches any character. `\.` matches a literal period. Common mistakes:

```regex
# Wrong — matches "com" at end of anything
^user@example.com$

# Right
^user@example\.com$
```

### Check greedy vs lazy

```regex
<.*>             # greedy — matches from first < to last > on the line
<.*?>            # lazy — matches the shortest <...>
```

If your regex is matching "too much," switch the relevant quantifier to lazy.

### Check case sensitivity

Without the `i` flag, `FOO` and `foo` are different. Add `i` if case shouldn't matter.

### Check multiline mode

By default, `^` and `$` match start/end of the whole string. With the `m` flag, they match start/end of each line. If you're operating on log files, `m` is usually what you want.

### Check dotall mode

By default, `.` does NOT match newline. With the `s` flag, it does. Needed when you want `<.*>` to span multiple lines.

### Check the Unicode flag

`[a-zA-Z]` matches only ASCII. Unicode letters (accents, Cyrillic, Chinese) don't match. Use:

```regex
[\p{Letter}]    # with u flag in JS, or re.UNICODE in Python
```

## "It's too slow" — ReDoS and catastrophic backtracking

Patterns with **nested quantifiers on overlapping character classes** can take exponential time.

### The classic bad pattern

```regex
^(a+)+$
```

On input `"aaaaaaaaaaaaaaaaaa!"` (20 a's + a !), the engine tries every way to split the a's between the inner `a+` and outer `+`. That's 2^20 paths — about a million operations — for a 21-character input.

### Real-world bad patterns

```regex
^(a|a)*$                # overlapping alternatives
^([a-zA-Z]+)*$          # nested +
^.*.*.*$                # nested any-char
```

### How to check for ReDoS

- Test with long, slightly-malformed input (e.g. 50 chars of valid pattern + 1 invalid char at the end).
- If the regex hangs or takes seconds, it has a backtracking problem.
- Tools: [safe-regex](https://www.npmjs.com/package/safe-regex) (npm), [regexploit](https://github.com/doyensec/regexploit) (Python).

### How to fix

1. **Remove nesting.** Rewrite `(a+)+` as `a+`.
2. **Use atomic groups** (PCRE/Java/Python 3.11+): `(?>a+)+` — no backtracking.
3. **Use possessive quantifiers** (same engines): `a++`, `a*+` — no backtracking.
4. **Move to a linear-time engine**: Go's RE2, Rust's `regex`, `ripgrep` without `-P`.

### Never trust user input

If untrusted users can supply the regex pattern itself, someone will supply a ReDoS pattern deliberately. Solutions:

- Compile with a timeout (Python: `regex` package; not `re`).
- Use a linear-time engine.
- Reject patterns longer than a limit.
- Sandbox the regex execution with a CPU timeout.

## Common mistakes by category

### Character class

```regex
# Wrong — matches a, -, z (the dash isn't a range here)
[-a-z]

# Right — to include a literal dash, put it first, last, or escape it
[a-z-]
[-a-z]       # also works
[a-z\-]
```

### Alternation precedence

```regex
# Wrong — matches "cat" OR "dog" OR (empty)
^cat|dog$

# Right
^(cat|dog)$
```

### Number ranges

Regex can't do numeric ranges naturally. `\d{1,3}` matches 0–999 and also "000", "042". For strict ranges:

```regex
# 0–255 (for IP octets)
(25[0-5]|2[0-4]\d|[01]?\d\d?)
```

For anything beyond ~3 digits, validate the match numerically after.

### Overlooking `\s`

`\s` includes tabs, newlines, and carriage returns — not just spaces. Match against mixed-whitespace input to confirm it's what you want.

### Backslash escaping in host strings

A pattern in a string literal needs its backslashes doubled:

```js
// JS regex literal
const re = /\d+/;

// JS string-based regex
const re = new RegExp("\\d+");
```

```python
# Python — always use raw strings for regex
re.compile(r'\d+')         # right
re.compile('\d+')          # works but fragile
```

Forgetting this produces "why is my regex matching nothing?"

## Debug-as-you-go workflow

1. Write the simplest pattern that matches your target.
2. Test on 5 real inputs — 3 that should match, 2 that shouldn't.
3. Tighten until it rejects the 2 while still matching the 3.
4. Test on a longer sample — does it still do what you expect?
5. Check with a test for a malicious input (long + malformed). Does it terminate in reasonable time?
6. Commit the pattern with a comment including at least one example input.
