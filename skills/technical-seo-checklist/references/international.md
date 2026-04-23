# International SEO

If your site serves multiple languages or regions, search engines need help figuring out which version to show to which user. Get this wrong and you get duplicate-content dilution or wrong-language traffic.

## The three URL strategies

Pick one and stick with it. Mixing creates dilution.

### 1. Subdirectory — `example.com/en/`, `example.com/uk/`

**Preferred** for most sites.

Pros:
- Single domain; all ranking signals accrue to one host.
- Cheap and easy to configure.
- Works with any CDN.

Cons:
- If you need per-country hosting (latency, data residency), you're on your own.

### 2. Subdomain — `en.example.com`, `uk.example.com`

Works, but Google treats subdomains as semi-separate sites. Ranking signals split between them. Only use if there are real technical reasons (separate hosting infrastructure per language).

### 3. ccTLD — `example.co.uk`, `example.de`

Strongest country targeting signal but the most expensive. Every domain ranks independently — you're starting from zero on each. Pick this only when the business case for country-specific branding is real.

## `hreflang` tags — the critical piece

For every page that has alternates in other languages, every alternate needs to reference every other alternate, including itself.

```html
<!-- On https://example.com/en/blog/rsc-guide -->
<link rel="alternate" hreflang="en" href="https://example.com/en/blog/rsc-guide" />
<link rel="alternate" hreflang="uk" href="https://example.com/uk/blog/rsc-guide" />
<link rel="alternate" hreflang="de" href="https://example.com/de/blog/rsc-guide" />
<link rel="alternate" hreflang="x-default" href="https://example.com/en/blog/rsc-guide" />
```

Rules:
- **Every variant includes every other variant**, including itself.
- **All `hreflang` references are reciprocal.** If `/en/` references `/uk/`, `/uk/` must reference `/en/`.
- **`x-default`** — the fallback for users whose language isn't covered. Usually English.
- **Absolute URLs, not relative.**
- **The language code follows ISO 639-1** (`en`, `uk`, `de`), optionally with ISO 3166-1 region (`en-US`, `en-GB`, `pt-BR`).

### Where to put hreflang

Three places, same effect — pick one:

1. **`<head>` of the HTML.** Easiest for small sites.
2. **HTTP headers** (`Link: <...>; rel="alternate"; hreflang="..."`). Required for non-HTML resources (PDFs).
3. **Sitemap.xml**. Best for large sites where managing per-page head tags is fragile:

```xml
<url>
  <loc>https://example.com/en/blog/rsc-guide</loc>
  <xhtml:link rel="alternate" hreflang="en" href="https://example.com/en/blog/rsc-guide" />
  <xhtml:link rel="alternate" hreflang="uk" href="https://example.com/uk/blog/rsc-guide" />
  <xhtml:link rel="alternate" hreflang="de" href="https://example.com/de/blog/rsc-guide" />
</url>
```

## Language vs region

- `en` — English, any region.
- `en-US` — English, US audience specifically.
- `en-GB` — English, UK audience specifically.
- `pt` — Portuguese, default.
- `pt-BR` — Brazilian Portuguese.
- `pt-PT` — European Portuguese.

Use language-only (`en`) when the content is identical across regions. Use language-region (`en-US`) when you have distinct content for US vs UK (different products, prices, spellings).

Don't use `hreflang="us"` or `hreflang="EN"` — case matters for regions (uppercase), and the format is `language-region`.

## Canonical + hreflang — combining the two

Canonical is per-page-self-referential. Hreflang points to translations.

```html
<!-- On https://example.com/en/blog/rsc-guide -->
<link rel="canonical" href="https://example.com/en/blog/rsc-guide" />
<link rel="alternate" hreflang="en" href="https://example.com/en/blog/rsc-guide" />
<link rel="alternate" hreflang="uk" href="https://example.com/uk/blog/rsc-guide" />
```

Common bug: canonical pointing across languages (`canonical` on the `/uk/` page pointing to `/en/`). This tells Google the Ukrainian version isn't the primary — it will drop it from the Ukrainian index.

## Do not auto-redirect based on IP or Accept-Language

Search engines crawl from various locations; auto-redirects send Googlebot (usually US-based) to only the English version, and it never discovers the others.

Instead:
- Serve the user's requested URL.
- Show a **banner or a prompt** suggesting another language if their `Accept-Language` differs: "This page is also available in Ukrainian — switch?"
- Let the user click. Remember their choice in a cookie or local storage.

## Sitemap per language or one combined

Either works. For large sites, per-language sitemaps (`sitemap-en.xml`, `sitemap-uk.xml`) referenced from a sitemap index file are easier to manage. Each sitemap contains only URLs for that language.

## Validation

- [Hreflang Testing Tool](https://technicalseo.com/tools/hreflang/) — check that your hreflang tags are reciprocal.
- Google Search Console → International Targeting report — surfaces errors.
- Screaming Frog — its hreflang report shows missing reciprocals in a crawl.

Broken hreflang is mostly silent — pages still work for users, but search engines ignore your intent and pick whichever version looks strongest. The only way to know is to check.
