# Testing

Every Stripe integration bug lands on a customer's statement. Test thoroughly before shipping.

## The Stripe CLI — your local webhook server

```bash
brew install stripe/stripe-cli/stripe
stripe login
```

### Forward live test-mode events to your dev server

```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
```

The CLI:
- Authenticates with your Stripe account in test mode.
- Creates a tunnel.
- Forwards every event from test mode to your localhost endpoint.
- Prints the webhook signing secret — copy this to your `.env` as `STRIPE_WEBHOOK_SECRET`.

Leave this running while you develop. Real Stripe events flow to your laptop.

### Trigger specific events

```bash
stripe trigger checkout.session.completed
stripe trigger customer.subscription.created
stripe trigger customer.subscription.updated
stripe trigger customer.subscription.deleted
stripe trigger invoice.payment_succeeded
stripe trigger invoice.payment_failed
```

Each command generates a realistic test-mode event and fires it at your forwarded endpoint. Your handler runs as if the event came from production.

Combine `stripe listen` + `stripe trigger` in two terminals to exercise every event type in under a minute.

### Replay a previous event

```bash
stripe events resend evt_xxxxxxxxxxxx
```

Useful for debugging handlers that failed. Fix your code, resend, verify.

## Test clocks — simulate time-based events

Subscriptions renew monthly. You don't want to wait 30 days to test the renewal path.

[Test clocks](https://docs.stripe.com/billing/testing/test-clocks) let you create a "frozen time" scope, advance it manually, and see subscription events fire as if the clock jumped.

```bash
# Create a test clock
stripe test_clocks create --name "test-renewal-flow"

# Create a customer tied to the clock
stripe customers create --name "test-user" --test-clock <clock_id>

# Create a subscription
# ... (via Checkout Session or API with the customer)

# Advance time by 31 days
stripe test_clocks advance <clock_id> --frozen-time $(date -d "+31 days" +%s)

# Your webhook handler receives the renewal events in real time.
```

Test-clock subscriptions also cost no real money. Safe to exercise cancellation, renewal, trial-end, and failure paths repeatedly.

## Tests to actually write

### 1. Happy-path subscription

```
1. Create checkout session
2. Complete it (use 4242 4242 4242 4242)
3. Assert webhook fires: customer.subscription.created
4. Assert DB state: status=active, correct priceId
5. Assert user has access to the paid tier
```

### 2. Trial to paid

```
1. Create a trial subscription
2. Assert status=trialing, user has access
3. Advance test clock past trial_end
4. Assert webhook: customer.subscription.updated (status → active)
5. Assert invoice.payment_succeeded
6. Assert DB still shows active
```

### 3. Failed renewal → retries → cancellation

```
1. Attach a card that will fail on renewal (use test token tok_chargeCustomerFail).
2. Advance clock past current_period_end.
3. Assert: invoice.payment_failed fires.
4. Advance clock past Stripe's retry window (configurable; default ~2 weeks).
5. Assert: customer.subscription.deleted fires.
6. Assert DB: status=canceled, user downgraded to free tier.
```

### 4. Cancel at period end

```
1. Cancel subscription with cancel_at_period_end=true.
2. Assert: customer.subscription.updated fires.
3. Assert DB: status=active, cancelAtPeriodEnd=true.
4. Assert user still has access.
5. Advance clock to current_period_end.
6. Assert: customer.subscription.deleted fires.
7. Assert user loses access.
```

### 5. Idempotent webhook delivery

```
1. Send the same event twice (use `stripe events resend`).
2. Assert handler processes only once.
3. Assert no double side-effects (no duplicate emails, no double-grant).
```

### 6. Signature verification

```
1. Send a request with missing stripe-signature header → 400.
2. Send a request with a forged signature → 400.
3. Send a valid signature → handler processes.
```

## Test cards

| Card | Behavior |
|------|----------|
| `4242 4242 4242 4242` | Always succeeds. |
| `4000 0000 0000 9995` | Always declines (insufficient funds). |
| `4000 0025 0000 3155` | Requires 3D Secure. |
| `4000 0000 0000 0341` | Fails on the second charge (good for renewal-failure tests). |

Full list at [Stripe test cards](https://docs.stripe.com/testing).

## CI tests

Stripe's API isn't a good dependency for CI. Two options:

### Option A — stub the Stripe client in tests

```ts
import Stripe from 'stripe';
jest.mock('stripe');

const StripeMock = Stripe as jest.MockedClass<typeof Stripe>;
StripeMock.prototype.webhooks = {
  constructEvent: jest.fn().mockReturnValue(fakeEvent),
};
```

Drive your handler with fixture events. Fast, deterministic, no network.

### Option B — replay real events

Capture real Stripe events (from `stripe listen --print-json > events.jsonl`) and replay them in CI against your handler. Higher fidelity, no network.

For integration tests against real Stripe, use a dedicated CI-only test-mode account with test clocks. Production account never appears in CI.

## Staging before production

Before flipping to live mode:

- [ ] Every webhook event from the 8 in [lifecycle-events.md](./lifecycle-events.md) has been triggered against staging and results verified.
- [ ] Idempotency test: same event fired twice; handler runs once.
- [ ] Signature verification tested with both valid and invalid signatures.
- [ ] Cancellation flow exercised with both immediate and end-of-period.
- [ ] Renewal failure flow exercised end-to-end (card failure → retries → cancel).
- [ ] Customer Portal (if used) linked from the app and tested: change plan, update card, cancel.
- [ ] Production Stripe dashboard has the live webhook endpoint registered, with the 8 events subscribed.
- [ ] Live-mode `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` are in production env; deploy validates they're not test-mode keys.
