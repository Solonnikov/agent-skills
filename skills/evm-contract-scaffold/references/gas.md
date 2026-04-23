# Gas and optimization awareness

Gas optimization is a late-stage concern. Correctness first, gas second. But a few patterns are cheap to adopt early and expensive to retrofit.

## When to optimize

- **Don't optimize hot loops prematurely.** Write clear code, measure with `forge snapshot` or `hardhat-gas-reporter`, then optimize the specific function that matters.
- **Do optimize storage layout from day one.** Reordering state variables after deploy is a breaking change — plan the slot layout once.
- **Do minimize external calls.** Each external call is at minimum ~2,600 gas cold / 100 gas warm.

## Storage layout

Variables pack into 32-byte slots in declaration order. Group small types together:

```solidity
// ❌ Uses 3 slots
contract Bad {
    uint256 a;
    uint128 b;
    uint256 c;
    uint128 d;
}

// ✅ Uses 2 slots (b + d pack into one slot)
contract Good {
    uint256 a;
    uint256 c;
    uint128 b;
    uint128 d;
}
```

Foundry's `forge inspect <Contract> storageLayout` shows the actual layout. For upgradeable contracts, **never reorder or change the type of existing variables** — only append.

## Loops and unbounded arrays

```solidity
// ❌ Gas scales with array length — can DoS the function.
function distribute(address[] calldata recipients, uint256 amount) external {
    for (uint256 i = 0; i < recipients.length; i++) {
        _send(recipients[i], amount);
    }
}
```

If the array can grow without bound, any caller can make the function prohibitively expensive to call. Mitigations:

- Pull-based payments: recipients call `claim()` individually.
- Pagination: process a chunk per call.
- Off-chain batching: merkle proofs for eligibility.

## `string` vs `bytes`

`string` inherits from `bytes`. For short known-length identifiers, `bytes32` is one storage slot and cheap to compare. Use `string` only when the value is genuinely variable-length text.

## `public` vs `external`

`external` is slightly cheaper for functions that are never called internally (args stay in calldata instead of being copied to memory). Default to `external` for top-level entry points; use `public` only when you also call the function from another function in the same contract.

## Common traps

### Re-entrancy via `call{value: ...}`

```solidity
// ❌ Unsafe — receiver can re-enter before balance is updated.
function withdraw() external {
    uint256 bal = balances[msg.sender];
    (bool ok, ) = msg.sender.call{value: bal}("");
    require(ok);
    balances[msg.sender] = 0;
}

// ✅ Checks-effects-interactions
function withdraw() external {
    uint256 bal = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool ok, ) = msg.sender.call{value: bal}("");
    require(ok);
}
```

Or use OpenZeppelin's `ReentrancyGuard` modifier.

### Integer division rounds toward zero

```solidity
// (3 * 100) / 1000 = 0
uint256 fee = amount * feeBps / 10_000;
if (amount < 10_000 / feeBps) { /* fee rounds to 0 */ }
```

Always think about rounding direction and whether zero-rounding creates an exploit (free actions, stuck balances).

### `block.timestamp` as randomness

```solidity
// ❌ Miners/validators can influence this by a few seconds.
uint256 random = uint256(keccak256(abi.encode(block.timestamp, msg.sender))) % 100;
```

For actual randomness: use Chainlink VRF or a commit-reveal scheme. `block.timestamp` is fine for coarse timing logic ("claim window is open") but not for anything financial.

### Unchecked arithmetic

```solidity
// Solidity 0.8+ checks arithmetic by default. Unchecked skips the check for gas.
unchecked {
    for (uint256 i = 0; i < items.length; ++i) {
        // loop counter can't realistically overflow
    }
}
```

Only use `unchecked` where you've proven overflow is impossible. Adding this to user-facing math is a common bug vector.

## Measuring

```bash
forge snapshot           # writes .gas-snapshot
forge snapshot --diff    # shows changes vs snapshot in CI

npx hardhat test         # with hardhat-gas-reporter in config
```

Commit `.gas-snapshot` to git. Review gas changes in PRs the same way you review behavior changes.
