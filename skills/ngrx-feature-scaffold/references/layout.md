# Feature layout and file roles

Standard layout for a single NgRx feature slice. Drop this inside the feature library or app module it belongs to.

```
<feature>/
├── +state/
│   ├── <feature>.models.ts       # State interface + domain types
│   ├── <feature>.actions.ts      # createActionGroup — events only
│   ├── <feature>.reducer.ts      # FEATURE_KEY, initialState, createReducer
│   ├── <feature>.selectors.ts    # createFeatureSelector + composed selectors
│   ├── <feature>.effects.ts      # async side effects, HTTP, socket, navigation
│   ├── <feature>.facade.ts       # public observable + dispatch API
│   ├── <feature>.reducer.spec.ts
│   ├── <feature>.selectors.spec.ts
│   └── <feature>.facade.spec.ts
├── components/                   # UI for this feature (optional)
├── services/                     # HTTP/socket services (optional)
└── <feature>.module.ts           # StoreModule.forFeature + EffectsModule.forFeature
```

## File-by-file responsibilities

**`<feature>.models.ts`**
- The single source of truth for the state shape.
- Exports `<Feature>State` interface.
- Exports any domain enums/types used across the slice.
- No runtime code beyond types + initial constants.

**`<feature>.actions.ts`**
- One `createActionGroup` per feature. `source` must be unique across the app (e.g. `'User Profile'`).
- Events named in plain English — `'Init User'`, `'Load User Success'`, `'Load User Failure'`.
- Success payloads carry the data; failure payloads carry the error.

**`<feature>.reducer.ts`**
- Exports `<FEATURE>_FEATURE_KEY = '<featureKey>'`.
- Exports `initialState: <Feature>State`.
- Exports `<feature>Reducer = createReducer(initialState, on(...), ...)`.
- Pure, synchronous, no side effects.

**`<feature>.selectors.ts`**
- `selectState = createFeatureSelector<<Feature>State>(<FEATURE>_FEATURE_KEY)`.
- Composed selectors for every piece of derived state components will need.
- No memoization hacks — let `createSelector` do its job.

**`<feature>.effects.ts`**
- Class decorated `@Injectable()`.
- Services injected via `inject()`.
- One effect per async action; co-locate success and failure dispatches.
- `{ dispatch: false }` for effects that only trigger side effects (navigation, toasts, localStorage).

**`<feature>.facade.ts`**
- `@Injectable({ providedIn: 'root' })`.
- Exposes `readonly` observables selected off the store.
- Exposes dispatch methods wrapping `store.dispatch(Actions.xxx(...))`.
- Single dependency: the `Store`.
- This is the ONLY interface components should use to interact with the feature's state.

**Feature module**
```ts
@NgModule({
  imports: [
    StoreModule.forFeature(<FEATURE>_FEATURE_KEY, <feature>Reducer),
    EffectsModule.forFeature([<Feature>Effects]),
  ],
})
export class <Feature>Module {}
```
