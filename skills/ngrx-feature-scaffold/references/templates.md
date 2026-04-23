# File templates

Copy, rename `<Feature>` / `<feature>` / `<featureKey>`, and adapt the state shape. These are the skeletons — keep the structure, customize the payloads.

## `<feature>.models.ts`

```ts
export interface <Feature>State {
  entity: <Feature> | null;
  list: <Feature>[];
  isLoading: boolean;
  error: string | null;
}

export interface <Feature> {
  id: string;
  // ...domain fields
}
```

## `<feature>.actions.ts`

```ts
import { createActionGroup, emptyProps, props } from '@ngrx/store';
import { <Feature> } from './<feature>.models';

export const <Feature>Actions = createActionGroup({
  source: '<Feature>',
  events: {
    'Init': emptyProps(),
    'Load List': emptyProps(),
    'Load List Success': props<{ items: <Feature>[] }>(),
    'Load List Failure': props<{ error: string }>(),
    'Select Item': props<{ id: string }>(),
    'Save Item': props<{ item: <Feature> }>(),
    'Save Item Success': props<{ item: <Feature> }>(),
    'Save Item Failure': props<{ error: string }>(),
  },
});
```

## `<feature>.reducer.ts`

```ts
import { createReducer, on } from '@ngrx/store';
import { <Feature>Actions } from './<feature>.actions';
import { <Feature>State } from './<feature>.models';

export const <FEATURE>_FEATURE_KEY = '<featureKey>';

export const initialState: <Feature>State = {
  entity: null,
  list: [],
  isLoading: false,
  error: null,
};

export const <feature>Reducer = createReducer(
  initialState,
  on(<Feature>Actions.loadList, state => ({ ...state, isLoading: true, error: null })),
  on(<Feature>Actions.loadListSuccess, (state, { items }) => ({ ...state, list: items, isLoading: false })),
  on(<Feature>Actions.loadListFailure, (state, { error }) => ({ ...state, isLoading: false, error })),
  on(<Feature>Actions.selectItem, (state, { id }) => ({ ...state, entity: state.list.find(i => i.id === id) ?? null })),
);
```

## `<feature>.selectors.ts`

```ts
import { createFeatureSelector, createSelector } from '@ngrx/store';
import { <FEATURE>_FEATURE_KEY } from './<feature>.reducer';
import { <Feature>State } from './<feature>.models';

export const select<Feature>State = createFeatureSelector<<Feature>State>(<FEATURE>_FEATURE_KEY);

export const selectList = createSelector(select<Feature>State, state => state.list);
export const selectEntity = createSelector(select<Feature>State, state => state.entity);
export const selectIsLoading = createSelector(select<Feature>State, state => state.isLoading);
export const selectError = createSelector(select<Feature>State, state => state.error);
export const selectHasEntity = createSelector(selectEntity, entity => entity !== null);
```

## `<feature>.effects.ts`

```ts
import { inject, Injectable } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { catchError, exhaustMap, map, of, switchMap } from 'rxjs';
import { <Feature>Actions } from './<feature>.actions';
import { <Feature>Service } from '../services/<feature>.service';

@Injectable()
export class <Feature>Effects {
  private readonly actions$ = inject(Actions);
  private readonly service = inject(<Feature>Service);

  loadList$ = createEffect(() =>
    this.actions$.pipe(
      ofType(<Feature>Actions.loadList),
      exhaustMap(() =>
        this.service.list().pipe(
          map(items => <Feature>Actions.loadListSuccess({ items })),
          catchError(err => of(<Feature>Actions.loadListFailure({ error: err.message ?? 'Unknown error' }))),
        ),
      ),
    ),
  );

  saveItem$ = createEffect(() =>
    this.actions$.pipe(
      ofType(<Feature>Actions.saveItem),
      switchMap(({ item }) =>
        this.service.save(item).pipe(
          map(saved => <Feature>Actions.saveItemSuccess({ item: saved })),
          catchError(err => of(<Feature>Actions.saveItemFailure({ error: err.message ?? 'Unknown error' }))),
        ),
      ),
    ),
  );
}
```

## `<feature>.facade.ts`

```ts
import { inject, Injectable } from '@angular/core';
import { Store } from '@ngrx/store';
import { <Feature>Actions } from './<feature>.actions';
import { <Feature> } from './<feature>.models';
import * as <Feature>Selectors from './<feature>.selectors';

@Injectable({ providedIn: 'root' })
export class <Feature>Facade {
  private readonly store = inject(Store);

  readonly list$ = this.store.select(<Feature>Selectors.selectList);
  readonly entity$ = this.store.select(<Feature>Selectors.selectEntity);
  readonly hasEntity$ = this.store.select(<Feature>Selectors.selectHasEntity);
  readonly isLoading$ = this.store.select(<Feature>Selectors.selectIsLoading);
  readonly error$ = this.store.select(<Feature>Selectors.selectError);

  loadList(): void {
    this.store.dispatch(<Feature>Actions.loadList());
  }

  selectItem(id: string): void {
    this.store.dispatch(<Feature>Actions.selectItem({ id }));
  }

  saveItem(item: <Feature>): void {
    this.store.dispatch(<Feature>Actions.saveItem({ item }));
  }
}
```

## `<feature>.module.ts`

```ts
import { NgModule } from '@angular/core';
import { EffectsModule } from '@ngrx/effects';
import { StoreModule } from '@ngrx/store';
import { <Feature>Effects } from './+state/<feature>.effects';
import { <feature>Reducer, <FEATURE>_FEATURE_KEY } from './+state/<feature>.reducer';

@NgModule({
  imports: [
    StoreModule.forFeature(<FEATURE>_FEATURE_KEY, <feature>Reducer),
    EffectsModule.forFeature([<Feature>Effects]),
  ],
})
export class <Feature>Module {}
```

## Standalone-app alternative

For Angular standalone apps without `NgModule`, register via providers instead:

```ts
// app.config.ts
provideState(<FEATURE>_FEATURE_KEY, <feature>Reducer),
provideEffects(<Feature>Effects),
```
