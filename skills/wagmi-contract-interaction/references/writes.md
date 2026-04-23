# Write patterns

Every write follows **simulate → write → wait**. Shortcutting this is the single most common source of broken wallet UX.

## The canonical flow

```tsx
import { useSimulateContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';

function TransferButton({ to, amount }: { to: Address; amount: bigint }) {
  const { data: simulation, error: simError } = useSimulateContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'transfer',
    args: [to, amount],
  });

  const { writeContract, data: hash, isPending } = useWriteContract();

  const { isLoading: isConfirming, isSuccess, isError, error: receiptError } =
    useWaitForTransactionReceipt({ hash });

  return (
    <button
      disabled={!simulation || isPending || isConfirming}
      onClick={() => simulation && writeContract(simulation.request)}
    >
      {isPending && 'Check your wallet...'}
      {isConfirming && 'Confirming...'}
      {isSuccess && 'Transferred'}
      {!isPending && !isConfirming && !isSuccess && 'Transfer'}
    </button>
  );
}
```

Why each step matters:

- **Simulate** reproduces the call on the RPC. If the contract would revert, `simError` is set before the user ever signs. Surface that error; don't let them pay gas for a guaranteed failure.
- **Write** triggers the wallet signature prompt. `hash` is set when the transaction is broadcast, not when it's confirmed.
- **Wait** polls for the receipt. `isSuccess` means the transaction landed with `status === 'success'`. `isError` means it reverted on-chain (different from a simulation failure).

## Chain guard

Never start a write on the wrong chain. Check first:

```tsx
const chainId = useChainId();
const { switchChain } = useSwitchChain();

if (chainId !== EXPECTED_CHAIN_ID) {
  return <button onClick={() => switchChain({ chainId: EXPECTED_CHAIN_ID })}>Switch network</button>;
}
```

## Input validation

Before `useSimulateContract`, validate everything that came from user input:

```ts
import { parseEther, isAddress } from 'viem';

const recipient: Address | null = isAddress(input) ? input as Address : null;
let amount: bigint | null = null;
try {
  amount = parseEther(inputAmount);
  if (amount <= 0n) amount = null;
} catch {
  amount = null;
}

const { data: simulation } = useSimulateContract({
  address: tokenAddress,
  abi: erc20Abi,
  functionName: 'transfer',
  args: recipient && amount ? [recipient, amount] : undefined,
  query: { enabled: !!recipient && !!amount },
});
```

## Optimistic UI

Show the user's action immediately, reconcile on receipt:

```tsx
const [optimisticBalance, setOptimisticBalance] = useState<bigint | null>(null);

function onClick() {
  setOptimisticBalance(currentBalance - amount);
  writeContract(simulation.request);
}

useEffect(() => {
  if (isSuccess) queryClient.invalidateQueries({ queryKey: [/* balance key */] });
  if (isError) setOptimisticBalance(null);  // revert on failure
}, [isSuccess, isError]);
```

## Duplicate-submit prevention

Disable the button while `isPending` or `isConfirming`. For belt-and-suspenders, track a local `submitted` ref and refuse to call `writeContract` twice with the same nonce-relevant input.

## Imperative writes (outside components)

```ts
import { simulateContract, writeContract, waitForTransactionReceipt } from 'wagmi/actions';

async function transfer(to: Address, amount: bigint) {
  const { request } = await simulateContract(wagmiConfig, {
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'transfer',
    args: [to, amount],
  });

  const hash = await writeContract(wagmiConfig, request);
  const receipt = await waitForTransactionReceipt(wagmiConfig, { hash });

  if (receipt.status !== 'success') throw new Error('Transaction reverted');
  return receipt;
}
```

## Approve + transferFrom pattern

ERC-20 approvals are a two-write sequence. Show both steps explicitly:

1. Read current allowance.
2. If allowance is insufficient: simulate + write `approve(spender, amount)`, wait for receipt.
3. Simulate + write the actual `transferFrom` (or whatever consumes the allowance).

**Do not request `approve(spender, type(uint256).max)` unless the user explicitly understands and accepts it.** Scope allowances to the exact amount needed.
