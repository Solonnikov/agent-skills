# Metadata and head tags

The `<head>` is the single most important SEO surface on the page. If the `<head>` is wrong, nothing else matters.

## The essentials — every page

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Unique page title — Site Name</title>
  <meta name="description" content="Short, accurate description of the page content. 120–160 characters." />
  <link rel="canonical" href="https://example.com/current-page" />

  <!-- Open Graph (Facebook, LinkedIn, Slack, Discord, Threads) -->
  <meta property="og:type" content="website" />
  <meta property="og:url" content="https://example.com/current-page" />
  <meta property="og:title" content="Same as <title> or a social-friendly variant" />
  <meta property="og:description" content="Same as description or a social-friendly variant" />
  <meta property="og:image" content="https://example.com/og-image-1200x630.png" />

  <!-- Twitter/X card -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:site" content="@yourhandle" />

  <!-- Favicon set -->
  <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
  <link rel="manifest" href="/site.webmanifest" />
</head>
```

## Title tag

- **Unique per page.** Never reuse. Google actively punishes duplicates.
- **50–60 characters.** Longer gets truncated in SERPs. Put the most important keyword first.
- **Format**: `<Specific page>` — `<Category>` — `<Brand>` (or `<Brand>: <Specific page>` for brand-first sites).
- **No stuffing.** "Best cheap amazing shoes shoes shoes" reads as spam and ranks worse than the honest version.

```html
<!-- Good -->
<title>React Server Components: a practical guide — Example.com</title>

<!-- Bad (generic) -->
<title>Blog Post</title>

<!-- Bad (stuffed) -->
<title>React RSC Server Components React Server Components Tutorial 2026</title>
```

## Meta description

- **Unique per page.**
- **120–160 characters.** Google shows ~155 on mobile, ~160 on desktop.
- **Descriptive, not promotional.** "Learn how to X" beats "Best X platform ever". The description's job is to get the click, not to rank.
- **Include the primary keyword naturally** — helps bolding in SERPs, which lifts CTR.

If you don't write one, Google will generate one from page content — usually worse than anything you'd write.

## Canonical URL

```html
<link rel="canonical" href="https://example.com/current-page" />
```

Canonical tells search engines: "If you find this content at multiple URLs, index *this* one."

When to use:
- **Self-referencing** on every original page (canonical points to itself). Cheap insurance against parameter variations (`?ref=`, `?utm_*`, `?sort=`).
- **Across duplicates** — canonical on a printer-friendly version points to the main version.
- **Across domains** — cross-posted content on Medium/dev.to should canonical back to your site.

Common bugs:
- **Canonical pointing to homepage from every page.** Nuclear — Google sees all pages as variants of the homepage. Most common SEO bug.
- **Canonical to a 404.** Takes out the canonical's target and hurts the source.
- **Canonical in an iframe or via JS.** Parsers read the server-rendered HTML. If your canonical is JS-injected, it's often missed.

## Open Graph (OG)

OG tags are what Facebook, LinkedIn, Slack, Discord, iMessage, and Threads show when someone shares your URL. They don't directly affect search ranking but affect CTR and social amplification.

Required minimum:
- `og:type` — `website`, `article`, `product`.
- `og:url` — the canonical URL.
- `og:title` — the card title (can match `<title>` or be optimized for social).
- `og:description` — one-line pitch.
- `og:image` — **1200×630 px, under 5MB, absolute URL**. Don't skip this — unbranded cards get 2x less engagement.

Dynamic OG images: generate per-page images at build time (for SSG) or at request time (for SSR). Next.js has `generateMetadata` + `ImageResponse` for this. For static sites, a script that renders HTML to PNG via Puppeteer / `@vercel/og` at deploy time works fine.

## Twitter/X card

X reads OG tags as fallback but prefers explicit Twitter tags:

```html
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:site" content="@yourhandle" />
<meta name="twitter:creator" content="@authorhandle" />
<!-- twitter:title, twitter:description, twitter:image optional — fall back to og:* -->
```

`summary_large_image` is the format you want 99% of the time. `summary` gives a small thumbnail.

## `lang` attribute

```html
<html lang="en">
<!-- or -->
<html lang="uk">
<html lang="en-US">
```

Tells browsers, screen readers, and search engines the primary language. Forgotten on ~30% of sites.

## Favicon + app icons

Minimum viable set:
- `favicon.ico` (multi-size ICO) or `favicon.svg`
- `apple-touch-icon.png` (180×180)
- `site.webmanifest` for PWA installability

Generate everything at once: [realfavicongenerator.net](https://realfavicongenerator.net) takes one source image and emits the full set.

## Framework-specific head management

- **Next.js App Router**: [`metadata` object](https://nextjs.org/docs/app/building-your-application/optimizing/metadata) and `generateMetadata` function.
- **Next.js Pages Router**: `<Head>` from `next/head`.
- **Angular**: `Meta` + `Title` services from `@angular/platform-browser`; for SSR, use Angular Universal.
- **SvelteKit**: `<svelte:head>` in the route component.
- **Astro**: plain HTML in the layout.
- **Vue / Nuxt**: `useHead()` composable.

In every case: **render metadata on the server**. A `<title>` injected via JS after hydration is seen by browsers but not always by crawlers.
