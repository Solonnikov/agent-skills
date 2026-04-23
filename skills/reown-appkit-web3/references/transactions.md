# Signing and transactions

AppKit hands you the connected provider; you use chain-native APIs for actual signing and broadcasting. AppKit does not own the transaction shape.

## Signing a message (auth flow — SIWE / SIWS)

The common use case is "prove you own this wallet" for backend login.

### 1. Server issues a nonce

```
POST /auth/nonce → { nonce: "<random 32-byte hex>", issuedAt: "<ISO>" }
```

Store the nonce server-side (Redis, DB) keyed by a session ID. **Never accept a nonce produced by the client.**

### 2. Client constructs the message

For EVM use SIWE format:

```
yourapp.com wants you to sign in with your Ethereum account:
0xAbC...

Sign in to Your App

URI: https://yourapp.com
Version: 1
Chain ID: 1
Nonce: <nonce from server>
Issued At: <ISO>
```

For Solana use a similar structured message (no formal standard — pick one and stick to it). Include: domain, address, nonce, issued-at, chain ID (`solana:...`).

### 3. Client signs

**EVM via wagmi:**
```ts
import { signMessage } from '@wagmi/core';
const signature = await signMessage(wagmiConfig, { message });
```

**Solana:**
```ts
const provider = modal.getWalletProvider('solana');
const encoded = new TextEncoder().encode(message);
const { signature } = await provider.signMessage(encoded);
```

**Bitcoin:**
```ts
const provider = modal.getWalletProvider('bip122');
const signature = await provider.signMessage({ address, message });
```

### 4. Server verifies

- Recover the signer from `(message, signature)` using the chain-appropriate verifier.
- Confirm the recovered address matches the claimed address.
- Confirm the nonce matches the one you issued and hasn't been used.
- Confirm the domain/URI in the message matches your origin.
- Confirm issued-at is within an acceptable window (~5 minutes).

**Never verify signatures in the browser only.** An attacker controls the browser; the server is where trust happens.

## Sending a transaction

**EVM:**
```ts
import { sendTransaction, waitForTransactionReceipt } from '@wagmi/core';

const hash = await sendTransaction(wagmiConfig, {
  to: '0x...',
  value: parseEther('0.1'),
  data: '0x',
});

const receipt = await waitForTransactionReceipt(wagmiConfig, { hash });
if (receipt.status !== 'success') throw new Error('Transaction reverted');
```

**Solana:**
```ts
const provider = modal.getWalletProvider('solana');
const { signature } = await provider.signAndSendTransaction(transaction);
const confirmation = await connection.confirmTransaction(signature);
```

**Bitcoin:**
```ts
const provider = modal.getWalletProvider('bip122');
const txid = await provider.sendTransfer({ account, recipient, amount });
```

## Input validation before signing

- **Amount**: parse into the chain's smallest unit (`wei`, `lamports`, `sats`) server-side or with a library (`parseEther`, not `Number * 1e18`). Reject negative or NaN.
- **Recipient address**: validate format per chain. EVM should be checksummed; Solana should be a valid base58 pubkey; Bitcoin should match bech32 or P2PKH.
- **Chain ID**: require the user to be on the expected chain before signing. Don't "just switch for them" silently — prompt them.

## State during a pending transaction

- Block repeat-submits (disable the button, set `isSubmitting`).
- Show the tx hash and a link to the block explorer immediately after sign.
- Poll for receipt with a timeout (30–60s for L2, 60–120s for mainnet).
- Expose a "transaction rejected / failed" error path — this is the common case, not the edge case.
