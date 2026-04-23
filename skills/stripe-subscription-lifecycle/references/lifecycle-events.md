# Lifecycle events

Stripe fires 100+ event types. Most don't matter to you. Here are the 8 that actually drive subscription state — what to do for each and what not to do.

## The 8 that matter

| Event | What happened | What your handler does |
|-------|---------------|------------------------|
| `checkout.session.completed` | User completed a Stripe Checkout session. | Link `stripe_customer_id` to your user. Do NOT grant access yet. |
| `customer.subscription.created` | Subscription now exists in Stripe. | Create the DB subscription record. Grant access if `status` is `active` or `trialing`. |
| `customer.subscription.updated` | Anything about the subscription changed. | Upsert the DB record. Re-evaluate access. Most events funnel through here. |
| `customer.subscription.deleted` | Subscription ended (canceled, exhausted retries, etc.). | Mark the DB record `canceled`. Revoke access (or honor end-of-period). |
| `invoice.payment_succeeded` | A renewal (or first payment) succeeded. | Update `current_period_end`. Reset any "past due" grace state. Send receipt if you want. |
| `invoice.payment_failed` | A payment attempt failed. | Don't panic — Stripe retries. Log, maybe email user about their card. Revoke access after grace period. |
| `customer.subscription.trial_will_end` | Trial ends in 3 days. | Email the user. Don't do anything else. |
| `customer.subscription.paused` / `resumed` | User paused or resumed via Customer Portal. | Update DB record. Revoke / restore access accordingly. |

Everything else you can ignore until you have a specific reason. Don't subscribe to `*` events — you'll drown in noise and ship handlers for things you don't understand.

## The dispatch handler

```ts
async function handleEvent(event: Stripe.Event) {
  switch (event.type) {
    case 'checkout.session.completed':
      await onCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
      break;

    case 'customer.subscription.created':
    case 'customer.subscription.updated':
      await upsertSubscription(event.data.object as Stripe.Subscription);
      break;

    case 'customer.subscription.deleted':
      await onSubscriptionEnded(event.data.object as Stripe.Subscription);
      break;

    case 'invoice.payment_succeeded':
      await onPaymentSucceeded(event.data.object as Stripe.Invoice);
      break;

    case 'invoice.payment_failed':
      await onPaymentFailed(event.data.object as Stripe.Invoice);
      break;

    case 'customer.subscription.trial_will_end':
      await onTrialEndingSoon(event.data.object as Stripe.Subscription);
      break;

    default:
      // Unhandled is fine — log and move on.
      log.debug('stripe.unhandled_event', { type: event.type });
  }
}
```

## Per-event handlers

### `checkout.session.completed`

```ts
async function onCheckoutCompleted(session: Stripe.Checkout.Session) {
  const userId = session.client_reference_id || session.metadata?.userId;
  if (!userId) return log.warn('Checkout session has no userId reference');

  await db.users.updateOne(
    { _id: userId },
    { $set: { stripeCustomerId: session.customer as string } }
  );
  // Do NOT grant access here. Wait for `customer.subscription.created`.
}
```

**Why not grant access here?** Because ACH payments, SEPA, and 3D Secure can complete the session but fail the first charge minutes later. If you grant access at checkout, you'll have users with access who never paid.

### `customer.subscription.created` / `updated`

These two share a handler — both represent "Stripe's subscription looks like this now; sync it."

```ts
async function upsertSubscription(sub: Stripe.Subscription) {
  const userId = await userIdFromCustomer(sub.customer as string);
  if (!userId) return log.error('No user for stripe customer', { customer: sub.customer });

  await db.subscriptions.updateOne(
    { stripeSubscriptionId: sub.id },
    {
      $set: {
        userId,
        stripeCustomerId: sub.customer as string,
        status: sub.status,
        cancelAtPeriodEnd: sub.cancel_at_period_end,
        currentPeriodStart: new Date(sub.current_period_start * 1000),
        currentPeriodEnd: new Date(sub.current_period_end * 1000),
        priceId: sub.items.data[0].price.id,
        productId: sub.items.data[0].price.product as string,
        canceledAt: sub.canceled_at ? new Date(sub.canceled_at * 1000) : null,
        endedAt: sub.ended_at ? new Date(sub.ended_at * 1000) : null,
        updatedAt: new Date(),
      },
    },
    { upsert: true },
  );

  await reevaluateUserTier(userId);  // flip entitlements based on new status
}
```

### `customer.subscription.deleted`

```ts
async function onSubscriptionEnded(sub: Stripe.Subscription) {
  await upsertSubscription(sub);  // mark canceled, set endedAt
  const userId = await userIdFromCustomer(sub.customer as string);
  if (!userId) return;

  await downgradeUserToFreeTier(userId);
  // Consider: send a "we'd love to have you back" email, optionally with a win-back coupon.
}
```

Downgrade logic should live in one place — `downgradeUserToFreeTier(userId)` — not scattered across every event handler. Think of it as a pure function of "what subscription does this user have?" → "what tier should they be?".

### `invoice.payment_failed`

```ts
async function onPaymentFailed(invoice: Stripe.Invoice) {
  const subscriptionId = invoice.subscription as string;
  if (!subscriptionId) return;

  // Don't immediately revoke access — Stripe will retry 3–4 times over ~2 weeks (configurable).
  // Just record the failure and decide based on grace-period policy.
  await db.subscriptions.updateOne(
    { stripeSubscriptionId: subscriptionId },
    { $set: { lastPaymentFailure: new Date(), updatedAt: new Date() } },
  );

  const userId = await userIdFromCustomer(invoice.customer as string);
  if (userId) await emailPaymentFailedNotification(userId);
}
```

Do NOT downgrade here. Downgrade happens when `customer.subscription.deleted` fires (after all retries are exhausted, per your Stripe dunning settings).

### `customer.subscription.trial_will_end`

Fires 3 days before `trial_end`. Email-only handler — don't change any state.

```ts
async function onTrialEndingSoon(sub: Stripe.Subscription) {
  const userId = await userIdFromCustomer(sub.customer as string);
  if (userId) await emailTrialEnding(userId, new Date(sub.trial_end! * 1000));
}
```

## Common mistakes

- **Granting access on `checkout.session.completed`.** See above — checkout intent ≠ payment.
- **Downgrading on `invoice.payment_failed`.** Premature; Stripe retries. Use `customer.subscription.deleted`.
- **Not handling `customer.subscription.updated`.** `updated` covers Customer-Portal plan changes, pauses, tier upgrades. Skipping it means your DB silently rots.
- **Assuming subscription events come in order.** They don't. A `customer.subscription.updated` might arrive before `customer.subscription.created` in pathological cases. Upsert, don't insert.
- **Treating `status` as a boolean.** See [subscription-states.md](./subscription-states.md) — there are 7 states, and "has access?" is a function of status + `cancel_at_period_end` + `current_period_end`.

## Ordering and race conditions

Webhook delivery is at-least-once but not strictly ordered. If event A was produced before event B, your handler might see B first. Defensive patterns:

- **Upsert, don't insert** — always.
- **Store `updatedAt`** and, when processing an event, skip if the event's `created` is older than your `updatedAt`. (Stripe events have a `created` timestamp.)
- **For money-movement events** (invoice.paid, charge.succeeded), the `created` timestamp is the source of truth for ordering within a subscription.
