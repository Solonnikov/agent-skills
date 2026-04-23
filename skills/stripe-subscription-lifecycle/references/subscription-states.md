# Subscription states

A Stripe `Subscription` has a `status` field that drives everything. Know all seven states and which of them grant access to your app.

## The seven statuses

| Status | Meaning | Grants access? | How it gets here |
|--------|---------|----------------|------------------|
| `incomplete` | First payment attempt hasn't completed yet (3D Secure, ACH pending). | **No** | Checkout completed but first invoice isn't paid. |
| `incomplete_expired` | First payment wasn't completed within 23 hours. Dead subscription. | No | `incomplete` → 23h timeout. |
| `trialing` | On a free trial period. | **Yes** | Subscription was created with a trial. |
| `active` | Normal, paying, up-to-date. | **Yes** | After first payment succeeded, or trial ended with a valid payment method. |
| `past_due` | Renewal payment failed; Stripe is retrying. | **Depends on your grace-period policy** | `active` → renewal payment failed. |
| `canceled` | User or system canceled. Period may or may not be over. | **Depends on `cancel_at_period_end` + current time** | User canceled, payment retries exhausted, or admin canceled. |
| `unpaid` | Retries exhausted; payment still missing. | No | `past_due` → retries exhausted (depends on your dunning config). |
| `paused` | Subscription paused (e.g., "pause billing" from Customer Portal). | No | User pauses via Customer Portal (if enabled). |

(Stripe sometimes adds statuses over time — `paused` is relatively recent. Check [current status list](https://docs.stripe.com/api/subscriptions/object#subscription_object-status) before relying on this.)

## "Does this user have access?" — the decision function

```ts
function hasActiveSubscription(subscription: Stripe.Subscription | null): boolean {
  if (!subscription) return false;

  // Full access states.
  if (subscription.status === 'active') return true;
  if (subscription.status === 'trialing') return true;

  // Grace-period policy: keep access while Stripe retries (optional).
  if (subscription.status === 'past_due' && inGracePeriod(subscription)) return true;

  // Canceled but still within paid period.
  if (subscription.status === 'canceled' &&
      subscription.cancel_at_period_end &&
      subscription.current_period_end * 1000 > Date.now()) {
    return true;
  }

  return false;
}
```

Run this function anywhere you gate features. Don't hand-roll the logic in five places.

## The two fields that trip people up

### `cancel_at_period_end: boolean`

When a user cancels via the Customer Portal, Stripe defaults to end-of-period cancellation:

- `cancel_at_period_end = true`
- `status` stays `active` until `current_period_end`
- At `current_period_end`, status flips to `canceled`
- `customer.subscription.deleted` webhook fires at that moment

This is what users expect ("I paid for the month, let me use what I paid for").

If the user wants immediate cancellation, or if an admin cancels via API:

- `cancel_at_period_end = false`
- `status` flips to `canceled` immediately
- `customer.subscription.deleted` webhook fires immediately

Your entitlement check needs to handle both: **canceled + period still in the future = keep access; canceled + period ended = revoke access.**

### `current_period_start` / `current_period_end`

Unix timestamps. `current_period_end` is when the next renewal attempt happens. Store both on your DB subscription record; update on every relevant webhook.

## State transitions — which your app cares about

```
Checkout → incomplete
           ↓ (first payment succeeds)
           active / trialing

active ─── (renewal fails) ──→ past_due
                                  ↓ (retries exhausted)
                                  unpaid / canceled  (per dunning config)

active ─── (user cancels at period end) ──→ active (with cancel_at_period_end=true)
                                              ↓ (period ends)
                                              canceled

active ─── (user/admin cancels immediately) ──→ canceled

active ─── (user pauses) ──→ paused ─── (user resumes) ──→ active
```

## Storing it in your DB

Minimum fields:

```ts
interface SubscriptionRecord {
  userId: string;
  stripeCustomerId: string;
  stripeSubscriptionId: string;
  status: 'incomplete' | 'trialing' | 'active' | 'past_due' | 'canceled' | 'unpaid' | 'paused';
  cancelAtPeriodEnd: boolean;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  priceId: string;           // which tier
  productId: string;         // which product
  canceledAt: Date | null;
  endedAt: Date | null;
  updatedAt: Date;           // for debugging webhook ordering issues
}
```

Don't invent your own `pending`, `expired`, or `active` states — mirror Stripe's `status` verbatim. Custom states on top of Stripe's accumulate bugs because they drift out of sync.
