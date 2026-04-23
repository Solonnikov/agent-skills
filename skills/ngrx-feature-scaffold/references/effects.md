# Effect operator cheatsheet

The choice of flattening operator in an effect is a correctness decision, not a style one. Picking the wrong one causes duplicate requests, lost updates, or stale UI.

## Decision table

| Operator | Use for | Behavior when a new source event arrives |
|----------|---------|------------------------------------------|
| `exhaustMap` | Idempotent one-shot loads, "init" actions, anything that shouldn't be triggered again while in flight | Ignores new source events until the inner observable completes. |
| `switchMap` | User-driven queries (typeahead, filter, navigation), or anytime only the latest request matters | Cancels the in-flight inner observable and subscribes to the new one. |
| `concatMap` | Writes where ordering is critical (sequential POSTs, queued edits) | Queues source events; processes them one at a time in order. |
| `mergeMap` | Fire-and-forget parallel operations where order doesn't matter | Subscribes to every inner observable concurrently. Use with care. |

## Rules of thumb

- **Default to `exhaustMap` for load actions.** Covers the common "user triple-clicks the refresh button" case.
- **Default to `switchMap` for search / filter effects.** You only care about the latest query.
- **Default to `concatMap` for writes.** A `POST /items` followed immediately by `PATCH /items/:id` must land in that order.
- Never use raw `map` and subscribe inside — always flatten through one of the operators above.
- Never nest `subscribe()` inside an effect. If you find yourself wanting to, you probably need another action.

## Success + failure dispatch

Every async effect should emit exactly one of two actions: success or failure. Co-locate them:

```ts
loadList$ = createEffect(() =>
  this.actions$.pipe(
    ofType(Actions.loadList),
    exhaustMap(() =>
      this.service.list().pipe(
        map(items => Actions.loadListSuccess({ items })),
        catchError(err => of(Actions.loadListFailure({ error: err.message ?? 'Unknown' }))),
      ),
    ),
  ),
);
```

## Side-effect-only effects

Use `{ dispatch: false }` when the effect reacts to an action but does not dispatch a new one — e.g., navigation, toasts, localStorage, analytics.

```ts
redirectOnLogin$ = createEffect(
  () =>
    this.actions$.pipe(
      ofType(Actions.loginSuccess),
      tap(() => this.router.navigateByUrl('/dashboard')),
    ),
  { dispatch: false },
);
```

## Composing state into an effect

When an effect needs current store state, use `withLatestFrom` or `concatLatestFrom`:

```ts
saveItem$ = createEffect(() =>
  this.actions$.pipe(
    ofType(Actions.saveItem),
    concatLatestFrom(() => this.store.select(selectCurrentUserId)),
    switchMap(([{ item }, userId]) =>
      this.service.save({ ...item, userId }).pipe(
        map(saved => Actions.saveItemSuccess({ item: saved })),
        catchError(err => of(Actions.saveItemFailure({ error: err.message }))),
      ),
    ),
  ),
);
```

`concatLatestFrom` is lazy — it only subscribes to the selector when the action fires, which avoids circular initialization issues.
