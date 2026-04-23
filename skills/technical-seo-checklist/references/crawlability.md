# Crawlability

Everything else is wasted if search engines can't crawl and index your pages. Check this first.

## `robots.txt`

```
# https://example.com/robots.txt
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Disallow: /*?utm_*

Sitemap: https://example.com/sitemap.xml
```

Rules:
- `robots.txt` is a *suggestion* — rogue crawlers ignore it. It's also *public* — anyone can read it. Don't use it to hide sensitive URLs; use auth.
- `User-agent: *` covers all bots. Add specific `User-agent: Googlebot` / `User-agent: Bingbot` sections only if you need different rules per crawler.
- `Disallow: /` on production blocks all crawling — a common staging-config-leaked-to-prod bug. Verify after every deploy.
- Always include a `Sitemap:` reference.

## `sitemap.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2026-04-20</lastmod>
  </url>
  <url>
    <loc>https://example.com/blog/rsc-guide</loc>
    <lastmod>2026-04-23</lastmod>
  </url>
</urlset>
```

Rules:
- **One URL per indexable page.** Don't include URLs you `Disallow` in robots.txt or `noindex`.
- **Absolute URLs only.** `/blog/foo` is invalid; must be `https://example.com/blog/foo`.
- **50,000 URLs max per file, 50 MB uncompressed.** For larger sites, use a sitemap index file that points to multiple sitemaps.
- **Update `lastmod` when content actually changes.** Lying (setting `lastmod: today` on everything) trains Google to ignore your sitemap.
- **Register the sitemap in Google Search Console.** Submitting manually speeds initial indexing.

For dynamic sites, generate the sitemap on build (SSG) or on request (SSR). Next.js has `app/sitemap.ts`; Astro has `@astrojs/sitemap`; most frameworks have an equivalent.

## `meta robots` — page-level control

```html
<meta name="robots" content="index, follow">     <!-- default, redundant -->
<meta name="robots" content="noindex, nofollow"> <!-- don't index, don't follow links -->
<meta name="robots" content="noindex, follow">   <!-- don't index this page, do follow its links -->
```

When to `noindex`:
- Thank-you pages, confirmation pages.
- Internal search results (infinite URL space, duplicate content).
- Low-quality tag pages that don't add value.
- Staging / preview environments — always noindex these.

When to **avoid** `noindex`:
- On important landing pages by accident. Common at launch.
- On category pages with filters — those are usually high-value.

`noindex` via `meta robots` only works if the page is *crawled*. If it's also disallowed in `robots.txt`, Google never reads the meta tag and may still show the URL in results without a snippet.

## `X-Robots-Tag` HTTP header — same thing, server-level

```
X-Robots-Tag: noindex, nofollow
```

Use when:
- The resource isn't HTML (PDFs, images, JSON).
- You want to apply rules to an entire directory from the server config.
- You can't modify the page template.

Staging environments often use this. Double-check it doesn't leak into production — the single most common cause of "we launched and traffic dropped to zero".

## Status codes and redirects

| Code | When |
|------|------|
| `200` | Normal, indexable page. |
| `301` | Permanent redirect. Passes ~all ranking to the destination. Use for moves, URL changes, canonicalization. |
| `302` | Temporary redirect. Does not pass ranking. Use only for actual temporary redirects (A/B tests, load balancing). |
| `404` | Page not found. Let Google drop it naturally. |
| `410` | Gone — intentionally removed. Slightly faster deindex than 404. Useful when you're sure a URL will never come back. |
| `5xx` | Server error. Persistent 5xx's tell Google to slow down crawling; long-term they cause deindex. |

**Never return 200 on a "not found" page.** "Soft 404s" (a 200 response with "Page not found" content) confuse Google and waste crawl budget.

## Pagination and faceted navigation

Two common crawl-budget killers.

### Pagination (`?page=2`, `?page=3`, etc.)

Google stopped using `rel="next" / rel="prev"` years ago, but the pattern to follow is still:

- Each page has a **self-referencing canonical** (don't canonical page 2 to page 1).
- The paginated URLs should be linked from the main category page — so Google can discover them.
- If pagination exists only for UX, not for unique content, consider `noindex` on page 2+.

### Faceted navigation (`/shoes?color=red&size=10&brand=nike`)

Every filter combination creates a URL. On a clothing site that's billions. Mitigations:

- Add filter-heavy combinations to `Disallow: /*?color=*` in robots.txt.
- Use `rel="canonical"` on filtered pages pointing to the un-filtered category.
- Use `noindex, follow` on filtered pages — they're not indexed but their product links are still crawled.

Crawl budget is finite. Every crap URL indexed is one less slot for a page that matters.

## Indexing speed tips

- **Submit sitemaps** in Search Console.
- **Internal links**: every indexable page should be linked from at least one other page on the same site. Orphan pages often don't get indexed.
- **Breadcrumbs with `BreadcrumbList` schema** help Google understand site hierarchy.
- **Request indexing** for critical new pages via Search Console's URL Inspection tool (`Request indexing` button). Limited in volume but useful for launches.
- **Internal cross-linking from high-traffic pages** to new content speeds discovery.

## What you can't control

- **How fast Google crawls you.** Gated by domain authority and server response time.
- **Whether Google chooses to index a page.** Google increasingly filters low-value pages even if they're technically indexable.
- **Keyword rankings.** You can influence; you cannot set.

If Search Console says "Discovered - currently not indexed" for many pages, that's Google's judgment on your content quality, not a technical bug. No amount of metadata fixes that — only better content does.
