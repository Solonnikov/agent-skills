# Common patterns

The 20 patterns people reuse constantly. Copy, verify with real input, adapt.

## Identifiers

### Email (pragmatic, not RFC-perfect)

```regex
^[^\s@]+@[^\s@]+\.[^\s@]+$
```

Matches `anything@anything.anything` with no whitespace. Good enough for 99% of use cases. Perfect validation is impossible; use a confirmation email.

### URL (HTTP/HTTPS)

```regex
^https?://[^\s/$.?#].[^\s]*$
```

Matches `http://...` and `https://...`. Permissive. For strict validation, use a URL parser in your language (`new URL()` in JS, `urllib.parse` in Python).

### UUID (v1–v5)

```regex
^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$
```

Case-insensitive flag recommended. The `[1-5]` is the version nibble; `[89ab]` is the variant.

### Semantic version

```regex
^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$
```

This is the [official semver regex](https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string). Captures major, minor, patch, pre-release, build.

Simpler version if you don't need pre-release/build captured:

```regex
^v?(\d+)\.(\d+)\.(\d+)$
```

### Git SHA (short or full)

```regex
^[0-9a-f]{7,40}$
```

Case-insensitive flag. Git SHAs are lowercase hex, 7–40 chars.

## Network

### IPv4

```regex
^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$
```

Strict — actually checks each octet is 0–255. The loose version `\d{1,3}(\.\d{1,3}){3}` is tempting but matches `999.999.999.999`.

### IPv6 (basic form only)

Full IPv6 with `::` shortening and mixed v4/v6 is a 400-character regex nobody writes correctly. Parse it instead. In JS: `new URL('http://[' + addr + ']').hostname`. In Python: `ipaddress.ip_address(addr)`.

### Port number

```regex
^([1-9]\d{0,3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5])$
```

0–65535. If you only care about common ports, just `^\d{1,5}$` and validate numerically.

### MAC address

```regex
^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$
```

Supports `AA:BB:CC:DD:EE:FF` and `AA-BB-CC-DD-EE-FF`.

## Dates and times

### ISO 8601 date

```regex
^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$
```

`YYYY-MM-DD`. Doesn't validate day-in-month (accepts 2026-02-31). Parse for that.

### ISO 8601 datetime

```regex
^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T(0\d|1\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?(Z|[+-](0\d|1[0-4]):[0-5]\d)?$
```

Parse if you need real validation. Use this to reject obviously-wrong shapes.

### HH:MM:SS time

```regex
^(0\d|1\d|2[0-3]):[0-5]\d:[0-5]\d$
```

24-hour clock.

## Strings and content

### Hex color

```regex
^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$
```

Supports `#RGB`, `#RRGGBB`, `#RRGGBBAA`.

### Phone number (permissive, international)

```regex
^\+?[\d\s()-]{7,20}$
```

Extremely permissive — just "digits, spaces, parens, dashes, optional leading +". Phone numbers are too varied for strict regex; use [libphonenumber](https://github.com/google/libphonenumber) for real validation.

### Slug (lowercase URL-safe)

```regex
^[a-z0-9]+(?:-[a-z0-9]+)*$
```

Matches `my-slug-123` — lowercase letters, digits, hyphens (no leading, trailing, or double hyphens).

### Base64 (standard)

```regex
^[A-Za-z0-9+/]+={0,2}$
```

Match but not validate — length must be a multiple of 4. For strict: `^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$`.

### URL-safe base64

```regex
^[A-Za-z0-9_-]+={0,2}$
```

Used by JWTs.

## Numbers

### Integer

```regex
^-?\d+$
```

### Positive integer

```regex
^\d+$
```

### Decimal

```regex
^-?\d+(\.\d+)?$
```

### Currency (USD-style, two decimals)

```regex
^\$?-?\d{1,3}(,\d{3})*(\.\d{2})?$
```

Matches `$1,234.56`. Requires thousands separator to be consistent.

## Log lines and extraction

### Extract key=value pairs from a log line

```regex
(\w+)=("[^"]*"|\S+)
```

Matches `user=alice` and `query="hello world"`. Use `g` (global) flag to find all.

### Extract a timestamp from a log line

```regex
\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}
```

Matches `2026-04-23 15:42:11` or `2026-04-23T15:42:11`.

### Extract an HTTP status code

```regex
HTTP/\d\.\d"\s(\d{3})\s
```

Typical access log format. The `(\d{3})` captures the status.

## Line-level patterns

### Blank lines

```regex
^\s*$
```

### Lines not starting with a `#` (skip comments)

```regex
^(?!#).+$
```

Uses a negative lookahead.

### Lines ending with a specific extension

```regex
\.(ts|tsx|js|jsx)$
```

### Leading whitespace

```regex
^[ \t]+
```

Strip with a replace.

## Usage cheat-sheet

| Goal | Pattern |
|------|---------|
| Require entire string to match | `^pattern$` |
| Match anywhere | `pattern` (don't anchor) |
| Case-insensitive | add `i` flag |
| Multiline `^` and `$` | add `m` flag |
| Global (replace all, match all) | add `g` flag |
| Unicode-aware `\d`, `\w`, `\s` | add `u` flag (JS); `re.UNICODE` (Python) |

Test everything at [regex101.com](https://regex101.com/) — pick the right flavor in the left sidebar.
