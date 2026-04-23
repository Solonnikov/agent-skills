# Core Web Vitals

Google uses three metrics as ranking signals. Hitting "Good" on all three is table stakes. Not hitting them is a ranking handicap.

## The three metrics

| Metric | What it measures | Good | Needs improvement | Poor |
|--------|------------------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | Time until the largest content element renders | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | Worst-case delay from user interaction to visual response | ≤ 200ms | ≤ 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | How much visible content shifts during load | ≤ 0.1 | ≤ 0.25 | > 0.25 |

(INP replaced FID — First Input Delay — in March 2024.)

Measured on real users via the Chrome UX Report (CrUX). Your Lighthouse lab score is a proxy, not the truth.

## LCP — Largest Contentful Paint

The LCP element is usually the hero image, the main heading, or a video poster.

### Fix plan

1. **Identify the LCP element.** Lighthouse tells you. Often it's an image above the fold.
2. **Serve it fast.**
   - Use `<img fetchpriority="high">` on the hero image.
   - Host static assets on a CDN.
   - Use modern formats (AVIF, WebP) with fallbacks.
   - Preload the hero image: `<link rel="preload" as="image" href="/hero.avif">`.
   - For SSR/SSG, inline critical CSS in `<head>` so the browser doesn't wait for a stylesheet.
3. **Don't lazy-load the LCP element.** `loading="lazy"` on the hero image is a common bug that tanks LCP.
4. **Avoid render-blocking resources** above the fold. No synchronous JS or CSS that blocks first paint.
5. **Reduce server response time (TTFB).** Under 600ms is the target. Caching, edge rendering, faster origins.

### Common LCP killers

- Client-side rendering where the LCP element is only painted after JS hydrates.
- Hero image loaded from a slow third-party CDN.
- Custom fonts with `font-display: block` — the text is invisible until the font loads.
- A full-page loader that blocks LCP from ever firing on the real content.

## INP — Interaction to Next Paint

Measures the worst interaction on the page. Clicks, taps, keypresses. Google uses the 75th percentile of your worst interactions.

### Fix plan

1. **Don't block the main thread.** Long tasks (>50ms) during interaction cause INP spikes.
2. **Split long JavaScript into chunks.** Code-split, lazy-load, defer anything not needed for initial interaction.
3. **Defer non-critical work** to `requestIdleCallback` or a post-interaction useEffect.
4. **Debounce expensive event handlers** (scroll, resize, input).
5. **Avoid heavy work in React's render path.** Memoize computations, virtualize lists, move work to workers.
6. **Instrument in production.** Use the [web-vitals](https://github.com/GoogleChrome/web-vitals) library to capture real-user INP.

### Common INP killers

- Unthrottled `onChange` handlers on text inputs that hit the server on every keystroke.
- Heavy JS bundles that parse during user interaction.
- Third-party scripts (analytics, chat widgets) that monopolize the main thread.
- `setState` on every scroll event.

## CLS — Cumulative Layout Shift

Layout shifts happen when an element moves after it's been painted. Annoying at best, broken clicks at worst.

### Fix plan

1. **Always set `width` and `height` on images and iframes.** The browser reserves space; no shift when the image loads.
2. **Reserve space for ads and dynamic content.** Use `aspect-ratio` CSS.
3. **Avoid inserting content above existing content.** Cookie banners, notices, "we value your privacy" — render them below or in overlays, not shifting the layout down.
4. **Use `font-display: optional` or preload fonts** to avoid the FOUT-to-custom-font reflow.
5. **Animate with `transform` / `opacity`**, not `top` / `width` / `height`. Transforms don't trigger layout.

### Common CLS killers

- `<img>` without width/height attributes, loading above the fold.
- Ad slots that push content down when the ad loads.
- Dynamic banners ("save 10% today!") injected at the top after load.
- Third-party embeds (tweets, Instagram posts) that resize after mounting.

## Measuring

### Real user data (CrUX)

- [Chrome UX Report](https://chromeuxreport.com/) — enter your URL, see the 28-day p75 values.
- Google Search Console → Core Web Vitals — URLs grouped as Good / Needs Improvement / Poor.
- [PageSpeed Insights](https://pagespeed.web.dev/) — shows both lab (Lighthouse) and field (CrUX) data.

### Lab data (Lighthouse)

- Chrome DevTools → Lighthouse panel.
- `npx lighthouse <url> --view` from the CLI.
- Lighthouse CI for per-PR regression tracking.

Lab data is directionally useful but not the ranking signal. If CrUX says "Poor" and Lighthouse says "Good", trust CrUX.

### In production

```html
<script>
  import { onCLS, onINP, onLCP } from 'web-vitals';
  onCLS(metric => sendToAnalytics('CLS', metric));
  onINP(metric => sendToAnalytics('INP', metric));
  onLCP(metric => sendToAnalytics('LCP', metric));
</script>
```

Capture p75 over your real traffic. Feed into your analytics tool. This is what Google sees.

## Framework-specific tips

- **Next.js**: `next/image` with `priority` prop on above-the-fold images. `next/font` for font-display optimization. `<Script strategy="lazyOnload">` for third-parties.
- **Angular**: `ngOptimizedImage` directive for priority, width/height, and automatic srcset. Angular Universal for SSR.
- **SvelteKit**: `@sveltejs/enhanced-img` for automatic AVIF/WebP and width/height.
- **Astro**: `<Image>` component from `astro:assets`.

Every mainstream framework has solved the common performance mistakes. Use their optimizations; don't hand-roll.

## Budget and regression tracking

Set a performance budget per route:

```js
// lighthouse-budget.json
[{
  "resourceSizes": [
    { "resourceType": "script", "budget": 180 },
    { "resourceType": "image",  "budget": 300 },
    { "resourceType": "total",  "budget": 1000 }
  ],
  "timings": [
    { "metric": "largest-contentful-paint", "budget": 2500 },
    { "metric": "cumulative-layout-shift",  "budget": 0.1 }
  ]
}]
```

Run Lighthouse CI on every PR against the budget. A performance regression should fail the build, the same way a broken test does.
