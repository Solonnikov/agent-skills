# Webhook setup

The webhook endpoint is the most important single piece of code in your Stripe integration. Get it wrong and your app drifts out of sync — users paying for plans they don't have, users with access they haven't paid for, or both.

## The endpoint — Express

```ts
import express from 'express';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
const app = express();

// IMPORTANT: express.raw() BEFORE any json parser, for THIS route only.
app.post(
  '/webhooks/stripe',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const sig = req.headers['stripe-signature'] as string;
    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET!,
      );
    } catch (err) {
      console.error('Webhook signature verification failed:', err);
      return res.status(400).send('Bad signature');
    }

    // Idempotency — have we processed this event before?
    const alreadyProcessed = await markEventProcessed(event.id);
    if (alreadyProcessed) return res.json({ received: true });

    try {
      await handleEvent(event);
    } catch (err) {
      console.error('Webhook handler failed:', err);
      return res.status(500).send('Handler error'); // Stripe will retry.
    }

    res.json({ received: true });
  },
);

// express.json() AFTER the webhook — for every other route.
app.use(express.json());
```

## Why `express.raw()` specifically

`stripe.webhooks.constructEvent()` computes an HMAC over the byte-exact request body. If Express has already parsed JSON, the body is now a JavaScript object, not bytes — and the hash won't match, even for legitimate events.

Two ways to get this right:

### Option A — Per-route raw parser (recommended)

```ts
app.post('/webhooks/stripe', express.raw({ type: 'application/json' }), handler);
app.use(express.json());  // everywhere else
```

Surgical. The webhook route sees the raw buffer; everything else sees parsed JSON.

### Option B — Mount `express.raw()` conditionally

```ts
app.use((req, res, next) => {
  if (req.originalUrl === '/webhooks/stripe') next();
  else express.json()(req, res, next);
});
app.use('/webhooks/stripe', express.raw({ type: 'application/json' }));
```

Works, but more fragile. Prefer A.

## Idempotency

Stripe retries on 5xx responses, on timeouts, and sometimes on successful-but-slow responses. Your handler will see duplicate deliveries. Examples of duplicates in the wild:

- Deploy mid-delivery — Stripe retries, you process twice.
- Handler takes 30s and crashes — Stripe thinks it failed; next retry succeeds; both ran.
- Legitimate duplicate delivery at Stripe's discretion.

**Pattern**: record the event ID on successful processing; skip if already recorded.

```ts
async function markEventProcessed(eventId: string): Promise<boolean> {
  try {
    await db.stripeEvents.insertOne({ _id: eventId, processedAt: new Date() });
    return false;  // first time
  } catch (err) {
    if (isDuplicateKeyError(err)) return true;  // duplicate — skip
    throw err;
  }
}
```

Use your DB's unique-constraint mechanism:
- MongoDB: `_id` as the Stripe event ID, catch duplicate-key error.
- Postgres: `INSERT ... ON CONFLICT DO NOTHING RETURNING id`.
- Redis: `SET eventId NX EX <retention>`.

Retention: keep processed event IDs for 30 days. Stripe doesn't retry beyond that.

## Signature verification failures

If `constructEvent` throws, it's one of:

1. **Wrong signing secret.** You deployed with the test secret but the webhook is configured for live mode (or vice versa). Check the Stripe dashboard.
2. **Body was parsed before verification.** See "Why express.raw()".
3. **Clock skew** on your server. Stripe signatures include a timestamp; if your clock is off by more than 5 minutes, verification fails.
4. **Someone is calling your endpoint with a fake payload.** Return 400. You'll see this on production — crawlers, security scanners, attackers. That's the point of the signature.

## Replay protection

Signature verification also prevents replay attacks — signatures include a timestamp, and Stripe's SDK rejects signatures older than 5 minutes by default. You don't need to add anything here; the SDK handles it.

## Multiple environments

Stripe has test mode and live mode. They have separate webhook endpoints, separate signing secrets, separate event IDs. Configure them separately in your env:

```
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

When you go live:

```
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_different_secret...
```

A test-mode signature NEVER verifies against a live-mode secret, and vice versa. This is good — test traffic can't contaminate live state.

## Endpoint discovery

Stripe needs a URL to send events to. Options:

- **Production**: `https://api.yourapp.com/webhooks/stripe`, registered in the Stripe dashboard.
- **Local development**: `stripe listen --forward-to localhost:3000/webhooks/stripe` — the CLI forwards live events from Stripe to your laptop through a tunnel.
- **Staging**: separate dashboard endpoint pointing at your staging URL.

## Observability

Log every event's `id`, `type`, and `livemode` flag — with redaction of everything else. You will need this. Sample:

```ts
log.info('stripe.webhook', {
  eventId: event.id,
  eventType: event.type,
  livemode: event.livemode,
  apiVersion: event.api_version,
});
```

Don't log the full event body — it contains PII (email, billing address) and sometimes partial card data (last 4, brand). Your log aggregator will thank you.
