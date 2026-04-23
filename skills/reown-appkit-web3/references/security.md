# Security checklist

Frontend Web3 code is a phishing and fund-loss surface. These are the threats that actually materialize; treat every box as a required review item.

## Wallet connection

- [ ] Project ID loaded from env config, not hard-coded.
- [ ] Different project IDs for dev / staging / prod.
- [ ] `metadata` — name, description, url, icons — matches the real app origin. Wrong metadata makes legitimate prompts look like phishing.
- [ ] Connection state resets fully on disconnect (address, chainId, type, walletInfo, listeners).
- [ ] No sensitive data in `localStorage` beyond what AppKit needs for its own session.
- [ ] Wallet `address` never used as a primary key in a user record without server-side verification.

## Signing for authentication

- [ ] Nonce generated server-side, never client-side.
- [ ] Nonce is single-use and time-bound.
- [ ] Message includes domain, nonce, chain ID, issued-at.
- [ ] Signature verified server-side using the chain's canonical verifier.
- [ ] Server rejects signatures whose recovered address doesn't match the claimed address.
- [ ] Server rejects messages whose domain doesn't match the API origin.

## Transaction flows

- [ ] Amount parsed with a chain-aware utility (`parseEther`, `parseUnits`, `BN`), never `Number * 1e18`.
- [ ] Negative and NaN amounts rejected.
- [ ] Recipient address format validated per chain.
- [ ] Chain ID checked before signing — refuse to sign on the wrong chain.
- [ ] Gas / fee estimation has a sensible fallback if RPC is unreachable.
- [ ] UI reflects pending → success / failed. Users never left wondering "did it go through?"
- [ ] Duplicate-submit prevention (button disabled while `isSubmitting`).
- [ ] Transaction hash displayed with an explorer link after sign.
- [ ] Receipt status verified before marking success.
- [ ] Rejected signatures handled with a user-facing "cancelled" message, not a generic error.

## Payment-specific

- [ ] Target amount, currency, and recipient are derived from server state — never built from user input on the client.
- [ ] Payment tracking uses a server-side order ID. The wallet address alone is not a sufficient key.
- [ ] Idempotency: re-submitting the same order doesn't double-charge.
- [ ] Failed payment has a recovery path (retry button, support link).

## Smart contract interaction

- [ ] Contract addresses come from trusted config, not URL params or user input.
- [ ] ABI version matches the deployed contract — pin ABIs to a version.
- [ ] Token approvals are scoped to the amount needed, not `type(uint256).max`, unless you've explicitly reviewed and accepted that risk.
- [ ] Read calls separated from write calls — no read function silently triggering a write.
- [ ] Revert reasons surfaced to the user in a readable form.

## Common phishing vectors to eliminate

- [ ] No "Sign this to continue" prompts that actually submit a transaction. Distinguish `signMessage` (free, no tx) from `sendTransaction` (costs gas, moves funds) in the UI copy.
- [ ] Transaction detail shown to the user matches what the contract will actually do (amount, recipient, token).
- [ ] No unsolicited approval prompts after a user "just connects."
- [ ] No blind-signing UX where the user sees opaque hex and a "Sign" button with no explanation.

## Operational

- [ ] Wallet addresses in server logs / analytics follow the privacy policy (typically hashed or masked).
- [ ] Sentry / error reporting redacts addresses and signatures.
- [ ] Rate-limit nonce issuance per IP + per address to mitigate enumeration.
