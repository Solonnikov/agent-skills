# Event subscriptions

## Live subscription

```ts
useWatchContractEvent({
  address: tokenAddress,
  abi: erc20Abi,
  eventName: 'Transfer',
  args: { from: userAddress },
  onLogs(logs) {
    // logs are typed based on the ABI
    for (const log of logs) {
      console.log(log.args.to, log.args.value);
    }
  },
});
```

Filter by indexed args server-side via `args` — the RPC applies the filter, so only matching logs are streamed.

## Historical events

```ts
import { getContractEvents } from 'viem/actions';

const logs = await getContractEvents(publicClient, {
  address: tokenAddress,
  abi: erc20Abi,
  eventName: 'Transfer',
  args: { from: userAddress },
  fromBlock: startBlock,
  toBlock: 'latest',
});
```

Returns all matching logs in the block range. Each log has `args` typed off the ABI event.

## Pagination for large ranges

Public RPCs cap `eth_getLogs` at a range (commonly 10,000 blocks). For longer ranges, paginate:

```ts
async function getEventsPaginated(fromBlock: bigint, toBlock: bigint, batchSize = 5_000n) {
  const all: Log[] = [];
  for (let start = fromBlock; start <= toBlock; start += batchSize) {
    const end = start + batchSize - 1n > toBlock ? toBlock : start + batchSize - 1n;
    const batch = await getContractEvents(publicClient, {
      address: tokenAddress,
      abi: erc20Abi,
      eventName: 'Transfer',
      fromBlock: start,
      toBlock: end,
    });
    all.push(...batch);
  }
  return all;
}
```

On RPCs that return "range too large" errors, halve `batchSize` and retry the failed segment.

## Decoding raw logs

If you already have logs from another source (e.g. an indexer), decode them with `decodeEventLog`:

```ts
import { decodeEventLog } from 'viem';

const decoded = decodeEventLog({
  abi: erc20Abi,
  data: log.data,
  topics: log.topics,
});
// decoded.eventName === 'Transfer', decoded.args is typed
```

## Event patterns to avoid

- **Subscribing without a filter** — `useWatchContractEvent` without `args` will fire for every event on the contract. For popular contracts (USDC, WETH) that's thousands per minute.
- **Polling historical logs in a tight loop** — one `getContractEvents` per block is expensive; use the live subscription for recent events and `getContractEvents` only for backfill.
- **Rendering state from raw logs** — logs from `useWatchContractEvent` are ephemeral. Persist to local state if you need them across re-renders.

## Subgraphs and indexers

For anything more than "events for the current user in the last N blocks," use an indexer (The Graph, Ponder, Envio) rather than frontend event queries. Frontend event polling doesn't scale past ~100k transactions.
