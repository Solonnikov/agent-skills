# Language differences

Same-looking regex syntax, different capabilities. Pick the flavor on regex101 that matches your runtime.

## JavaScript

- Engine: V8 (and Safari/Firefox equivalents). PCRE-like, backtracking.
- Syntax: `/pattern/flags` or `new RegExp('pattern', 'flags')`.
- Flags: `g`, `i`, `m`, `s`, `u`, `y` (sticky), `d` (indices).
- **No** `\A` / `\z` — use `^` / `$` with or without `m` flag.
- **No** extended (`x`) mode — write one-line regexes or build them with template strings.
- **Lookbehind**: supported in modern V8 (Chrome 62+, Node 10+, Safari 16+).
- **Named groups**: `(?<name>...)`, accessed as `match.groups.name`.
- **Unicode property escapes** (with `u` flag): `\p{Letter}`, `\p{Number}`, etc.

```js
const m = "hello world".match(/(?<greeting>\w+)\s(?<target>\w+)/);
m.groups.greeting;  // "hello"
m.groups.target;    // "world"
```

## Python

- Engine: `re` module. Backtracking.
- Syntax: `re.compile(r'pattern', flags)`.
- Flags: `re.IGNORECASE` (`i`), `re.MULTILINE` (`m`), `re.DOTALL` (`s`), `re.UNICODE` (`u`), `re.VERBOSE` (`x`).
- **Has** `\A` (start of string), `\z` / `\Z` (end of string).
- **Extended (`x`) mode**: supported — write multi-line regexes with comments.
- **Named groups**: `(?P<name>...)` (Python-specific `P`), accessed as `match.group('name')`.
- **Lookbehind**: fixed-width only in `re`. Use `regex` (third-party) for variable-width lookbehind.

```python
import re
m = re.match(r'(?P<greeting>\w+)\s(?P<target>\w+)', 'hello world')
m.group('greeting')  # 'hello'
m.group('target')    # 'world'
```

## PCRE (grep, ripgrep, sed, awk on some systems)

- Engine: PCRE2. Backtracking.
- Feature-rich: named groups `(?<name>...)`, lookbehind (fixed-width), atomic groups `(?>...)`, possessive quantifiers `*+`, `++`, `?+`.
- `grep` by default uses BRE (basic regex). `grep -E` uses ERE. `grep -P` uses PCRE.
- `ripgrep` uses Rust's `regex` (linear-time by default) — very different!

### `ripgrep` (`rg`) note

`ripgrep`'s engine is Rust's `regex` crate. It's linear-time (no backtracking), which means:

- **No lookaround** (neither `(?=)` nor `(?<=)`).
- **No backreferences** (`\1`, etc.).
- **No atomic groups** or possessive quantifiers.

To opt into PCRE2 features: `rg -P '...'`. Slower but full-featured.

## Go (RE2)

- Engine: RE2. **Linear-time.** No backtracking.
- Import: `"regexp"`.
- **No lookaround**, **no backreferences**, **no atomic groups**, **no possessive quantifiers**.
- **Named groups**: `(?P<name>...)` (same syntax as Python).

```go
re := regexp.MustCompile(`(?P<greeting>\w+)\s(?P<target>\w+)`)
m := re.FindStringSubmatch("hello world")
// Use re.SubexpIndex("greeting") to find the group index.
```

Go's RE2 is safe from ReDoS by design. You pay by giving up some features.

## Rust (`regex` crate)

- Same linear-time guarantee as RE2.
- Opt into PCRE via `fancy-regex` crate if you need backrefs/lookaround.

## .NET

- Engine: `System.Text.RegularExpressions`. Backtracking by default; in newer .NET you can opt into non-backtracking.
- Feature-rich: variable-width lookbehind, balancing groups, named groups, `(?<name>...)`.

## What to pick when writing public regex

- **For config files / validation that runs once**: any engine works; use the richest flavor available.
- **For user-input-driven matching on a server**: prefer linear-time (Go, Rust, ripgrep). ReDoS is a real attack vector.
- **For logs + command-line use**: PCRE via `ripgrep -P` or `grep -P`.

## Common portability issues

### `\d` meaning

- JavaScript without `u` flag: ASCII digits only.
- JavaScript with `u`: Unicode digits.
- Python: Unicode digits by default (configurable with `re.ASCII`).
- Go: ASCII digits only.

If exact Unicode matters, be explicit — use `[0-9]` for ASCII, `\p{Number}` for Unicode.

### `\w` meaning

Same split as `\d` — `[A-Za-z0-9_]` in ASCII-first engines, broader in Unicode-first. Test with real Unicode inputs if it matters.

### Capture group numbering

All engines: `\1`, `\2`, etc. — numbered by opening `(`.
Numbering ignores non-capturing groups `(?:...)`.

### Escaping

Inside character classes, fewer things need escaping:
- `[.+*]` — literal dot, plus, asterisk.
- Outside: `\.`, `\+`, `\*` — same chars need escaping.

Always escape `\` itself (`\\` in the regex, `\\\\` in a C-style string).

## Quick decision table

| Need | Use |
|------|-----|
| Client-side JS validation | JS regex, no special flags |
| Server validation of untrusted input | Go / Rust / RE2 |
| Log parsing on a laptop | `ripgrep` |
| Complex data extraction | Python `re` or `regex` |
| Refactoring across a codebase | `rg -P '...'` (your editor too) |
