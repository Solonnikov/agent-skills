# Connection state management

AppKit exposes state through three overlapping channels. Understanding what each one tells you prevents "stuck" connection states.

## The three channels

1. **`modal.subscribeState(cb)`** — high-level modal state: is it open, which view is showing, what account is selected.
2. **`modal.subscribeEvents(cb)`** — user-action events: `connect_success`, `disconnect`, `chain_changed`, etc.
3. **Adapter-specific watchers**:
   - Wagmi: `watchAccount`, `watchChainId`, `watchConnections` from `@wagmi/core`.
   - AppKit providers: `modal.subscribeProviders(cb)` for Solana/Bitcoin.
   - Native listeners: `window.solana.on('accountChanged', ...)`, `window.phantom.bitcoin.on('accountsChanged', ...)` for Phantom-specific edge cases.

## Minimum state shape

```ts
interface WalletState {
  isConnected: boolean;
  type: 'evm' | 'solana' | 'bitcoin' | null;
  address: string | null;
  chainId: string | null;
  walletName: string | null;
  isConnecting: boolean;
  error: string | null;
}
```

Keep it framework-agnostic — this is the interface you expose to the rest of the app. Store it wherever your app already manages state (Redux, Zustand, NgRx, a signal, whatever).

## Subscribing and syncing

```ts
function wireUp(modal: AppKit, wagmiConfig: Config, setState: (s: WalletState) => void) {
  const unsubs: (() => void)[] = [];

  unsubs.push(modal.subscribeState(() => syncFromModal(modal, setState)));
  unsubs.push(modal.subscribeEvents(event => {
    if (event.data.event === 'disconnect') setState(disconnected());
  }));

  unsubs.push(watchAccount(wagmiConfig, {
    onChange(account) {
      if (!account.isConnected) return;
      setState(fromEvmAccount(account));
    },
  }));

  unsubs.push(watchChainId(wagmiConfig, {
    onChange(chainId) {
      setState(prev => ({ ...prev, chainId: `eip155:${chainId}` }));
    },
  }));

  return () => unsubs.forEach(fn => fn());
}
```

## `syncFromModal` — the normalization function

This is the one piece everyone writes wrong the first time. AppKit's active account comes back as a CAIP string; parse it once and use typed fields everywhere else.

```ts
function syncFromModal(modal: AppKit, setState: (s: WalletState) => void) {
  const active = modal.getCaipAddress();
  if (!active) return setState(disconnected());

  const { type, chainId, address } = parseCaipAccount(active);
  const walletInfo = modal.getWalletInfo();

  setState({
    isConnected: true,
    type,
    address,
    chainId,
    walletName: walletInfo?.name ?? null,
    isConnecting: false,
    error: null,
  });
}
```

## Phantom-specific listeners

Phantom emits account/network changes on `window.solana` and `window.phantom.bitcoin` that AppKit sometimes misses (race conditions on fast switches). If you support Phantom, add listeners directly:

```ts
window.solana?.on('accountChanged', pubkey => {
  if (!pubkey) return setState(disconnected());
  setState(prev => ({ ...prev, address: pubkey.toString() }));
});

window.phantom?.bitcoin?.on('accountsChanged', accounts => {
  if (!accounts?.length) return setState(disconnected());
  setState(prev => ({ ...prev, address: accounts[0].address }));
});
```

Remember to remove these listeners on disconnect — they'll leak otherwise.

## Reconcile on mount

Users refresh pages. Wallets auto-reconnect. Don't assume the user is disconnected on app load:

```ts
async function reconcileOnMount(modal: AppKit) {
  const active = modal.getCaipAddress();
  if (active) syncFromModal(modal, setState);
}
```

Call this once after `createAppKit` returns.

## Disconnect

```ts
async function disconnect() {
  await modal.disconnect();
  unsubscribeAll();
  removeNativeListeners();
  setState(disconnected());
}
```

Always await `modal.disconnect()` — it's async and your listeners may still fire after `setState` if you don't.
