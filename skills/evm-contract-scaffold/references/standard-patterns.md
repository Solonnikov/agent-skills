# Standard contract patterns

Start from OpenZeppelin. Override only what you need.

## ERC-20

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
```

Hooks worth knowing: `_update` (OZ 5+) replaces `_beforeTokenTransfer` / `_afterTokenTransfer`. Override `_update` for transfer-time logic (pausing, fee-on-transfer, snapshot, etc.).

## ERC-721

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    uint256 private _nextId;

    constructor(address initialOwner) ERC721("MyNFT", "MNFT") Ownable(initialOwner) {}

    function mint(address to, string memory uri) external onlyOwner returns (uint256 id) {
        id = _nextId++;
        _safeMint(to, id);
        _setTokenURI(id, uri);
    }

    // Required overrides for multiple inheritance.
    function _update(address to, uint256 tokenId, address auth)
        internal override(ERC721, ERC721Enumerable) returns (address)
    { return super._update(to, tokenId, auth); }

    function _increaseBalance(address account, uint128 value)
        internal override(ERC721, ERC721Enumerable)
    { super._increaseBalance(account, value); }

    function tokenURI(uint256 tokenId)
        public view override(ERC721, ERC721URIStorage) returns (string memory)
    { return super.tokenURI(tokenId); }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool)
    { return super.supportsInterface(interfaceId); }
}
```

`ERC721Enumerable` is expensive (storage write on every transfer). Skip it if you don't need on-chain enumeration — most projects query via events / subgraph.

## ERC-1155

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyMulti is ERC1155, Ownable {
    constructor(address initialOwner, string memory baseURI)
        ERC1155(baseURI)
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        external onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}
```

For soulbound (non-transferable) tokens, override `_update` to revert on transfers between non-zero addresses. The ERC-5192 interface (`locked(uint256)`) is worth implementing for marketplace compatibility.

## Access control

Two choices:

### `Ownable` — single owner

```solidity
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Foo is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    function adminOnly() external onlyOwner { /* ... */ }
}
```

Use when there's exactly one authority. Simple, cheap, clear.

### `AccessControl` — roles

```solidity
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Foo is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    function mint(...) external onlyRole(MINTER_ROLE) { /* ... */ }
}
```

Use when multiple parties have distinct permissions. The admin role can grant/revoke others. Consider `AccessControlDefaultAdminRules` (OZ 4.9+) for two-step admin transfer, which is safer than the default one-step `transferOwnership`.

## Upgradeability

Only if you need it. Upgrade-by-default is a smell — most contracts should be immutable.

### UUPS proxy (recommended over Transparent)

```solidity
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FooV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address admin) public initializer {
        __Ownable_init(admin);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
```

**Use `@openzeppelin/contracts-upgradeable`, not the regular `contracts/` package.** The upgradeable variants use initializers instead of constructors and keep storage layouts upgrade-safe.

**Use `@openzeppelin/hardhat-upgrades`** (Hardhat) or **`openzeppelin-foundry-upgrades`** (Foundry) to deploy and manage upgrades — they run storage-layout checks to prevent unsafe upgrades.

## Custom errors

```solidity
error Unauthorized(address caller);
error AmountTooLow(uint256 provided, uint256 required);

function foo() external {
    if (msg.sender != owner) revert Unauthorized(msg.sender);
    if (msg.value < MIN) revert AmountTooLow(msg.value, MIN);
}
```

Cheaper than revert strings, and viem/wagmi/ethers all decode them into typed errors on the frontend.

## Events

```solidity
event Deposit(address indexed from, uint256 amount);
event Withdraw(address indexed to, uint256 amount);

function deposit() external payable {
    // ...
    emit Deposit(msg.sender, msg.value);
}
```

Index addresses and topic values you'll want to filter on. Keep three or fewer indexed parameters per event.
