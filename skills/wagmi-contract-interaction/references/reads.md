# Read patterns

## Single read

```ts
const { data: balance, isLoading, error } = useReadContract({
  address: tokenAddress,
  abi: erc20Abi,
  functionName: 'balanceOf',
  args: [userAddress],
});
```

With typed bindings from `wagmi/cli`:

```ts
const { data: balance } = useReadMyTokenBalanceOf({
  args: [userAddress],
});
```

## Conditional read

Don't call `useReadContract` with `undefined` args and hope it works — use `query.enabled`:

```ts
const { data } = useReadContract({
  address: tokenAddress,
  abi: erc20Abi,
  functionName: 'balanceOf',
  args: userAddress ? [userAddress] : undefined,
  query: { enabled: !!userAddress },
});
```

## Batched reads

Use `useReadContracts` for multiple calls in one RPC round-trip. The RPC cost drops from N to 1.

```ts
const { data } = useReadContracts({
  contracts: [
    { address: tokenAddress, abi: erc20Abi, functionName: 'symbol' },
    { address: tokenAddress, abi: erc20Abi, functionName: 'decimals' },
    { address: tokenAddress, abi: erc20Abi, functionName: 'balanceOf', args: [userAddress] },
  ],
});
// data is a tuple: [{ result: 'USDC' }, { result: 6 }, { result: 1000000n }]
```

Each entry has `{ status, result, error }` — one read can fail without failing the whole batch.

## Multicall

If your chain has Multicall3 deployed (most mainnets do), wagmi uses it automatically for `useReadContracts`. Verify with `multicall: true` on the chain config. If Multicall3 isn't available, wagmi falls back to N individual calls, which is slower but works.

## Watch-mode reads

Some values change mid-session (balances, block number, pending nonces). Use `watch: true` to re-read on every new block:

```ts
const { data: balance } = useReadContract({
  address: tokenAddress,
  abi: erc20Abi,
  functionName: 'balanceOf',
  args: [userAddress],
  query: { refetchInterval: 12_000 },  // or: watch: true on older wagmi
});
```

Use sparingly — every watched read is a recurring RPC cost.

## Imperative reads

Outside a React component, use the viem function directly:

```ts
import { readContract } from 'viem/actions';
import { getPublicClient } from 'wagmi/actions';

const client = getPublicClient(wagmiConfig);
const balance = await readContract(client, {
  address: tokenAddress,
  abi: erc20Abi,
  functionName: 'balanceOf',
  args: [userAddress],
});
```

Useful for effect logic, server-side code, scripts.

## Stale data and cache invalidation

Wagmi + React Query caches reads by `(address, abi, functionName, args)`. To force a refetch — e.g. after a successful write:

```ts
const queryClient = useQueryClient();

// after a successful transfer:
queryClient.invalidateQueries({ queryKey: [{ address: tokenAddress, functionName: 'balanceOf' }] });
```

Or rely on `watch: true` / `refetchInterval` for frequently-changing state.
