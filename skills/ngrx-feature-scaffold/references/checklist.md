# Pre-merge checklist

Run through this before shipping a new NgRx feature.

## Structure

- [ ] `+state/` folder contains exactly the six files (models, actions, reducer, selectors, effects, facade) plus their `.spec.ts` counterparts.
- [ ] Reducer and effects registered via `StoreModule.forFeature` / `EffectsModule.forFeature` (or `provideState` / `provideEffects` in standalone).
- [ ] `<FEATURE>_FEATURE_KEY` constant is exported and used everywhere the key is needed.

## Actions

- [ ] `createActionGroup` with a unique `source`.
- [ ] Every event name reads like an event in the past (`Loaded`, `Saved`, `Failed`), not a command (`Load`, `Save`).
- [ ] Every async operation has a `Success` and `Failure` pair.

## Reducer

- [ ] Pure — no `new Date()`, no `Math.random()`, no service calls, no conditional `if (window)`.
- [ ] Every state change is via object spread — no mutation.
- [ ] All async operations update a loading flag on start and clear it on success/failure.

## Selectors

- [ ] Feature selector uses `createFeatureSelector<State>(KEY)`.
- [ ] No component recomputes derived state — if it's derived, there's a selector.
- [ ] No `select(state => ...)` inline in components — always a named selector.

## Effects

- [ ] Correct flattening operator for each case (see effects.md).
- [ ] Every async effect dispatches exactly one of `Success` / `Failure`.
- [ ] Services injected via `inject()`, not constructor parameters.
- [ ] No nested `subscribe()`.
- [ ] Side-effect-only effects are marked `{ dispatch: false }`.

## Facade

- [ ] `@Injectable({ providedIn: 'root' })`.
- [ ] Only dependency is `Store`.
- [ ] Exposes `readonly` observables for everything components need.
- [ ] Exposes dispatch methods for every action components trigger.
- [ ] Is the only state-related thing components import.

## Tests

- [ ] Reducer: one `it` per action handler, plus one for the default case.
- [ ] Selectors: use `.projector()` — don't go through the real store.
- [ ] Facade: `provideMockStore` + spy on `dispatch`.

## Components using the feature

- [ ] Inject the facade, not the store.
- [ ] Use `async` pipe in templates — no manual subscribes.
- [ ] No action imports anywhere outside `+state/`.
