# Error handling

Wagmi surfaces errors as typed viem error classes. Branch on them to give the user the right message.

## The error classes you'll actually see

| Error | Meaning | UX |
|-------|---------|-----|
| `UserRejectedRequestError` | User cancelled in their wallet. | Silent. No toast, no Sentry. The user did what they meant to do. |
| `InsufficientFundsError` | Not enough native token for gas. | "Insufficient <ETH/MATIC/...> for gas fees." |
| `ContractFunctionRevertedError` | Contract reverted during simulation or execution. | Decode the revert reason (see below). |
| `ChainMismatchError` | User's wallet is on a different chain than expected. | Prompt to switch chain. |
| `ConnectorNotConnectedError` | No wallet connected. | Prompt to connect. |
| `HttpRequestError` / `TimeoutError` | RPC failure. | Show "Network error, try again" — don't leak the URL. |

Import from `viem`:

```ts
import {
  UserRejectedRequestError,
  InsufficientFundsError,
  ContractFunctionRevertedError,
  ChainMismatchError,
} from 'viem';
```

## Branching on error type

```ts
function handleWriteError(err: unknown): string | null {
  if (err instanceof UserRejectedRequestError) return null;  // silent
  if (err instanceof InsufficientFundsError) return 'Insufficient balance for gas fees.';
  if (err instanceof ChainMismatchError) return 'Please switch to the correct network.';
  if (err instanceof ContractFunctionRevertedError) {
    return decodeRevertReason(err) ?? 'Transaction would fail. Check your inputs.';
  }
  return 'Something went wrong. Please try again.';
}
```

## Decoding revert reasons

`ContractFunctionRevertedError` has structured detail when the contract uses custom errors or `require` messages:

```ts
function decodeRevertReason(err: ContractFunctionRevertedError): string | null {
  // Custom errors (Solidity 0.8.4+)
  if (err.data?.errorName) return humanizeCustomError(err.data.errorName, err.data.args);

  // require("message") — legacy Error(string)
  if (err.reason) return err.reason;

  // Panic codes (arithmetic overflow, assert, etc.)
  return null;
}

function humanizeCustomError(name: string, args: readonly unknown[]): string {
  switch (name) {
    case 'InsufficientBalance': return 'Not enough tokens.';
    case 'Unauthorized':        return 'You are not authorized to perform this action.';
    case 'Paused':              return 'This action is currently disabled.';
    default:                    return `Error: ${name}`;
  }
}
```

Keep a per-contract map of custom error name → user-facing message. Raw error names are not acceptable UI copy.

## Simulation errors vs execution errors

- **Simulation error** (`useSimulateContract` returns `error`) — caught before signing. No gas paid. Block the write button.
- **Execution error** (`useWaitForTransactionReceipt` returns `isError`) — the transaction landed on-chain and reverted. Gas was consumed. Show a different, more apologetic message; the user already paid.

## Rate-limiting and retries

On public RPCs (Alchemy free tier, public nodes), you'll see 429s. Wagmi retries automatically with backoff. For imperative code:

```ts
async function withRetry<T>(fn: () => Promise<T>, tries = 3): Promise<T> {
  for (let i = 0; i < tries; i++) {
    try { return await fn(); }
    catch (err) {
      if (i === tries - 1) throw err;
      await new Promise(r => setTimeout(r, 500 * 2 ** i));
    }
  }
  throw new Error('unreachable');
}
```

Don't retry user-rejected actions or contract reverts — those aren't flaky.

## Reporting

Redact addresses and signatures from Sentry / your error tracker before sending:

```ts
Sentry.captureException(err, {
  extra: {
    chainId,
    contract: 'MyToken',
    function: 'transfer',
    // do NOT include: addresses, amounts, signatures, tx hashes
  },
});
```

Address + amount + contract together can correlate to a specific user's holdings — treat as PII.
