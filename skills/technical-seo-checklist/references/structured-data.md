# Structured data (Schema.org / JSON-LD)

Structured data is how you tell Google what your page *is*, beyond what the text says. Done right, it gets you rich results in search — stars, images, price, breadcrumbs — which lift CTR significantly.

## JSON-LD is the format you want

Google supports three formats (JSON-LD, Microdata, RDFa). Only use JSON-LD. It's a separate script block, doesn't pollute the HTML, easy to generate.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "React Server Components: a practical guide",
  "datePublished": "2026-04-20T09:00:00Z",
  "dateModified": "2026-04-23T12:00:00Z",
  "author": {
    "@type": "Person",
    "name": "Jane Author",
    "url": "https://example.com/authors/jane"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Example",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  },
  "image": "https://example.com/og-image-1200x630.png",
  "mainEntityOfPage": "https://example.com/blog/rsc-guide"
}
</script>
```

## Types that actually produce rich results

Don't waste effort on schemas that don't enhance SERPs. Focus on:

| Type | When to use | What you get |
|------|-------------|--------------|
| `Article` / `BlogPosting` / `NewsArticle` | Editorial content | Author attribution, publish date, top stories carousel eligibility |
| `Product` | E-commerce products | Price, availability, rating stars, image |
| `Recipe` | Cooking content | Rating, time, calories, image carousel |
| `FAQPage` | FAQ sections | Expandable Q&A in SERP (rarer than it used to be but still helpful) |
| `HowTo` | Step-by-step guides | Numbered steps in SERP |
| `BreadcrumbList` | Category hierarchies | Breadcrumb trail in SERP instead of raw URL |
| `Organization` / `LocalBusiness` | Brand pages, contact info | Knowledge panel eligibility |
| `VideoObject` | Video content | Video thumbnail in SERP, video carousel |
| `Event` | Concerts, webinars, conferences | Dates + location in SERP |
| `Review` / `AggregateRating` | User reviews | Star rating in SERP |

Types that *used to* produce rich results but don't anymore — Google quietly retires them. Check [Google's rich results gallery](https://developers.google.com/search/docs/appearance/structured-data/search-gallery) to see what's currently live.

## Validate every schema

Three tools, all free:

1. [Rich Results Test](https://search.google.com/test/rich-results) — Google's own tool. Says explicitly whether your page qualifies for rich results.
2. [Schema.org Validator](https://validator.schema.org/) — checks that the JSON-LD is structurally valid.
3. Google Search Console → "Enhancements" — shows which schemas are detected across your site once indexed.

**Every schema goes through the Rich Results Test before merging.** "I added schema" without validation is ~50% likely to be broken.

## Implementation patterns

### Per-page, inline in the `<head>`

Simplest. Each template emits its own JSON-LD.

```tsx
// Next.js App Router
export default function ArticlePage({ article }) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: article.title,
    // ...
  };
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <article>...</article>
    </>
  );
}
```

### Generated from a source of truth

Keep the data in one place (CMS, frontmatter, database). Render JSON-LD from it. Never hand-write both.

### Schema helpers

Libraries like [`schema-dts`](https://github.com/google/schema-dts) (TypeScript types for Schema.org) catch mistakes at build time:

```ts
import type { Article, WithContext } from 'schema-dts';

const jsonLd: WithContext<Article> = {
  '@context': 'https://schema.org',
  '@type': 'Article',
  headline: article.title,
  // Type-checked — wrong field names won't compile.
};
```

## What not to do

- **Don't add schema for content that isn't on the page.** Hidden JSON-LD saying "5 star rating" when no reviews are visible → manual penalty risk.
- **Don't use multiple `@type`s hoping one sticks.** Google picks the most specific; extras are ignored or penalized.
- **Don't stuff keywords into `description` or `name` fields.** Same rules as regular metadata.
- **Don't skip `@context`.** Without `"@context": "https://schema.org"`, it's not valid JSON-LD.
- **Don't link to a `logo` image larger than 112×112 or smaller than 48×48** — Google's rendered logo spec. Use a clean PNG with transparent background.

## Schema for internationalization

If the same entity exists in multiple languages, give each page's JSON-LD an `@id` pointing to the canonical URL in that language. Then cross-link using `sameAs`:

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "@id": "https://example.com/en/rsc-guide",
  "sameAs": [
    "https://example.com/uk/rsc-guide",
    "https://example.com/de/rsc-guide"
  ],
  "headline": "..."
}
```

Combined with `hreflang` tags (see international.md), this tells Google the translations exist and link to each other.
