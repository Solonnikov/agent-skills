# Test patterns

Reducer, selectors, and facade each get a focused `.spec.ts`. Effects are intentionally omitted from required coverage — they're integration-heavy and often better covered by end-to-end tests. If you do test them, use `provideMockActions` + marble tests.

## Reducer tests — one `it` per action

```ts
import { <feature>Reducer, initialState } from './<feature>.reducer';
import { <Feature>Actions } from './<feature>.actions';

describe('<feature> reducer', () => {
  it('returns the initial state on an unknown action', () => {
    expect(<feature>Reducer(undefined, { type: 'NOOP' } as never)).toEqual(initialState);
  });

  it('sets isLoading on loadList', () => {
    const result = <feature>Reducer(initialState, <Feature>Actions.loadList());
    expect(result.isLoading).toBe(true);
    expect(result.error).toBeNull();
  });

  it('stores items on loadListSuccess', () => {
    const items = [{ id: '1' }, { id: '2' }];
    const result = <feature>Reducer({ ...initialState, isLoading: true }, <Feature>Actions.loadListSuccess({ items }));
    expect(result.list).toEqual(items);
    expect(result.isLoading).toBe(false);
  });

  it('stores error on loadListFailure', () => {
    const result = <feature>Reducer({ ...initialState, isLoading: true }, <Feature>Actions.loadListFailure({ error: 'boom' }));
    expect(result.error).toBe('boom');
    expect(result.isLoading).toBe(false);
  });
});
```

## Selector tests — use `.projector()`

Selectors created with `createSelector` expose a `.projector()` that takes resolved inputs, not the whole store tree. Test the pure function, skip the plumbing.

```ts
import * as <Feature>Selectors from './<feature>.selectors';

describe('<feature> selectors', () => {
  const state = {
    entity: { id: '1' },
    list: [{ id: '1' }, { id: '2' }],
    isLoading: false,
    error: null,
  };

  it('selectList returns the list', () => {
    expect(<Feature>Selectors.selectList.projector(state)).toEqual(state.list);
  });

  it('selectHasEntity is true when entity is set', () => {
    expect(<Feature>Selectors.selectHasEntity.projector({ id: '1' })).toBe(true);
  });

  it('selectHasEntity is false when entity is null', () => {
    expect(<Feature>Selectors.selectHasEntity.projector(null)).toBe(false);
  });
});
```

## Facade tests — `provideMockStore` + dispatch spy

```ts
import { TestBed } from '@angular/core/testing';
import { provideMockStore, MockStore } from '@ngrx/store/testing';
import { <Feature>Actions } from './<feature>.actions';
import { <Feature>Facade } from './<feature>.facade';

describe('<Feature>Facade', () => {
  let facade: <Feature>Facade;
  let store: MockStore;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideMockStore({ initialState: {} })],
    });
    facade = TestBed.inject(<Feature>Facade);
    store = TestBed.inject(MockStore);
    jest.spyOn(store, 'dispatch');
  });

  it('loadList dispatches Actions.loadList', () => {
    facade.loadList();
    expect(store.dispatch).toHaveBeenCalledWith(<Feature>Actions.loadList());
  });

  it('selectItem dispatches Actions.selectItem with id', () => {
    facade.selectItem('abc');
    expect(store.dispatch).toHaveBeenCalledWith(<Feature>Actions.selectItem({ id: 'abc' }));
  });
});
```

## What to skip

- **Don't test `createAction` / `createActionGroup`** — it's library code. Tests for "does the action exist" add no signal.
- **Don't test reducers through the store** — use the reducer function directly with a synthetic state.
- **Don't test selectors through the store** — use `.projector()`.
