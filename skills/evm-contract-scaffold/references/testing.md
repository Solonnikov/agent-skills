# Testing

Tests are the primary defense against losing funds. Aim for high coverage on every external function, every access-control branch, every math-sensitive path.

## Foundry

### Unit test

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");

    function setUp() public {
        token = new MyToken(owner);
    }

    function test_ownerCanMint() public {
        vm.prank(owner);
        token.mint(alice, 100e18);
        assertEq(token.balanceOf(alice), 100e18);
    }

    function test_nonOwnerCannotMint() public {
        vm.prank(alice);
        vm.expectRevert();
        token.mint(alice, 100e18);
    }
}
```

Key cheatcodes:
- `vm.prank(addr)` — next call comes from `addr`.
- `vm.startPrank / vm.stopPrank` — bracket multiple calls.
- `vm.expectRevert()` / `vm.expectRevert(bytes4 selector)` / `vm.expectRevert("msg")`.
- `vm.warp(timestamp)` / `vm.roll(blocknum)`.
- `makeAddr("label")` — creates a deterministic test address.

### Fuzzing

```solidity
function testFuzz_mintIncreasesBalance(address to, uint256 amount) public {
    vm.assume(to != address(0));
    amount = bound(amount, 0, type(uint128).max);

    vm.prank(owner);
    token.mint(to, amount);
    assertEq(token.balanceOf(to), amount);
}
```

`bound(x, lo, hi)` maps any input into a range — better than `vm.assume(amount < ...)` which wastes runs.

### Invariant testing

```solidity
contract InvariantTest is Test {
    MyToken token;

    function setUp() public {
        token = new MyToken(address(this));
    }

    function invariant_totalSupplyMatchesSumOfBalances() public {
        // `targetContract` defaults to `token`; Foundry will call random functions.
        // Assert a property that must always hold.
        assertGe(token.totalSupply(), 0);
    }
}
```

Invariant tests run a sequence of random calls and assert properties after each. Great for AMMs, lending protocols, any system with conservation laws.

### Forking

```solidity
function setUp() public {
    vm.createSelectFork("mainnet", 19_500_000);  // uses foundry.toml rpc_endpoints
}

function test_interactsWithRealUsdc() public {
    IERC20 usdc = IERC20(0xA0b8...);
    // Test against real on-chain state.
}
```

Forking reproduces chain state at a specific block. Use for integration tests against real protocols.

## Hardhat (TypeScript)

```ts
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';

describe('MyToken', () => {
  async function deploy() {
    const [owner, alice] = await ethers.getSigners();
    const MyToken = await ethers.getContractFactory('MyToken');
    const token = await MyToken.deploy(owner.address);
    return { token, owner, alice };
  }

  it('owner can mint', async () => {
    const { token, owner, alice } = await loadFixture(deploy);
    await token.connect(owner).mint(alice.address, ethers.parseEther('100'));
    expect(await token.balanceOf(alice.address)).to.equal(ethers.parseEther('100'));
  });

  it('non-owner cannot mint', async () => {
    const { token, alice } = await loadFixture(deploy);
    await expect(token.connect(alice).mint(alice.address, 100n))
      .to.be.revertedWithCustomError(token, 'OwnableUnauthorizedAccount');
  });
});
```

`loadFixture` caches the deployed state between tests — every `it` restarts from the same snapshot instead of redeploying.

## Coverage

- Foundry: `forge coverage` — line + branch coverage.
- Hardhat: `solidity-coverage` plugin.

Aim for 100% line coverage on business logic. Don't chase coverage on OpenZeppelin-inherited code — it's already tested upstream.

## Gas snapshots

- Foundry: `forge snapshot` writes `.gas-snapshot`. Commit it. PRs that change gas costs surface in the diff.
- Hardhat: `hardhat-gas-reporter` prints a table after tests run. Less CI-friendly but informative.

## What to test

- Every external function, happy path and revert path.
- Every access-control branch (owner vs non-owner, each role).
- Edge cases in math (overflow, underflow, zero, `type(uint256).max`).
- Events — assert they emit with the right args.
- State transitions — balances, allowances, mappings after every mutation.
- Revert with custom errors — `vm.expectRevert(MyContract.Unauthorized.selector)`.

## What not to test

- OpenZeppelin's own internals — trust the upstream tests.
- The compiler — `a + b == b + a` isn't interesting.
- Implementation details that change with refactors — test observable behavior.
