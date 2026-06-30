---
name: state-management
description: State management patterns for React, Vue, and Angular (Redux, Zustand, Pinia, NgRx). Use when choosing or implementing a state-management approach, structuring stores, or reviewing state logic.
---

# State Management Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** State management patterns for React, Vue, and Angular
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL state management decisions** in DeJoule products:
- Choosing between Redux, Zustand, Pinia, or NgRx
- Implementing global state
- Managing server state vs client state
- Optimizing re-renders and performance

---

## 🔄 State Management Decision Tree

```
Is the data from an API?
├── Yes → Use React Query / Vue Query (Server State)
└── No → Is it global state?
    ├── Yes → Use Redux Toolkit / Zustand / Pinia (Client State)
    └── No → Use component state (useState / ref)
```

### Server State (API Data)

**ALWAYS use data fetching libraries:**

- **React:** `@tanstack/react-query`
- **Vue:** `@tanstack/vue-query`
- **Angular:** `@ngneat/effects` or custom RxJS

**WHY:**
- Automatic caching
- Background refetching
- Optimistic updates
- Error/loading states

### Client State (Global UI State)

**Use when:**
- User preferences (theme, language)
- UI state (modals, drawers)
- Form state (multi-step forms)
- Authentication state

---

## 📦 Redux Toolkit (React)

### Store Setup Pattern

```typescript
import { configureStore } from '@reduxjs/toolkit';
import { featureReducer } from './slices/featureSlice';

/**
 * @description Redux store configuration
 */
export const store = configureStore({
  reducer: {
    feature: featureReducer,
    // Add other reducers
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: false, // Disable if needed
    }),
});

/**
 * @description RootState type
 */
export type RootState = ReturnType<typeof store.getState>;

/**
 * @description AppDispatch type
 */
export type AppDispatch = typeof store.dispatch;
```

### Slice Pattern

```typescript
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

/**
 * @description Feature state interface
 */
interface FeatureState {
  isActive: boolean;
  selectedId: string | null;
  items: Item[];
}

/**
 * @description Initial state
 */
const initialState: FeatureState = {
  isActive: false,
  selectedId: null,
  items: [],
};

/**
 * @description Feature slice
 */
export const featureSlice = createSlice({
  name: 'feature',
  initialState,
  reducers: {
    /**
     * @description Set active state
     */
    setActive: (state, action: PayloadAction<boolean>) => {
      state.isActive = action.payload;
    },

    /**
     * @description Set selected ID
     */
    setSelectedId: (state, action: PayloadAction<string | null>) => {
      state.selectedId = action.payload;
    },

    /**
     * @description Add item
     */
    addItem: (state, action: PayloadAction<Item>) => {
      state.items.push(action.payload);
    },

    /**
     * @description Reset state
     */
    reset: () => initialState,
  },
});

export const { setActive, setSelectedId, addItem, reset } =
  featureSlice.actions;

export default featureSlice.reducer;
```

### Typed Hooks Pattern

```typescript
import { useDispatch, useSelector } from 'react-redux';
import type { RootState, AppDispatch } from './store';

/**
 * @description Typed useAppDispatch hook
 */
export const useAppDispatch = () => useDispatch<AppDispatch>();

/**
 * @description Typed useAppSelector hook
 */
export const useAppSelector = <T>(selector: (state: RootState) => T): T => {
  return useSelector(selector);
};
```

### Usage in Component

```typescript
import { useAppDispatch, useAppSelector } from '@/store/hooks';
import { setActive, setSelectedId } from '@/store/slices/featureSlice';

export function FeatureComponent() {
  const dispatch = useAppDispatch();

  // Select state
  const isActive = useAppSelector((state) => state.feature.isActive);
  const selectedId = useAppSelector((state) => state.feature.selectedId);

  // Dispatch actions
  const handleActivate = () => {
    dispatch(setActive(true));
  };

  const handleSelect = (id: string) => {
    dispatch(setSelectedId(id));
  };

  return (
    <div>
      <button onClick={handleActivate}>Activate</button>
      <p>Selected: {selectedId}</p>
    </div>
  );
}
```

---

## 📦 Zustand (React/Vanilla)

### Store Pattern

```typescript
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

/**
 * @description Feature state interface
 */
interface FeatureState {
  // State
  isActive: boolean;
  selectedId: string | null;

  // Actions
  setActive: (active: boolean) => void;
  setSelectedId: (id: string | null) => void;
  reset: () => void;
}

/**
 * @description Feature store
 */
export const useFeatureStore = create<FeatureState>()(
  devtools(
    persist(
      (set) => ({
        // Initial state
        isActive: false,
        selectedId: null,

        // Actions
        setActive: (active) => set({ isActive: active }),
        setSelectedId: (id) => set({ selectedId: id }),
        reset: () => set({ isActive: false, selectedId: null }),
      }),
      {
        name: 'feature-storage', // LocalStorage key
      }
    )
  )
);
```

### Usage in Component

```typescript
import { useFeatureStore } from '@/stores/featureStore';

export function FeatureComponent() {
  // Select state
  const isActive = useFeatureStore((state) => state.isActive);
  const selectedId = useFeatureStore((state) => state.selectedId);

  // Select actions
  const setActive = useFeatureStore((state) => state.setActive);
  const setSelectedId = useFeatureStore((state) => state.setSelectedId);

  return (
    <div>
      <button onClick={() => setActive(true)}>Activate</button>
      <p>Selected: {selectedId}</p>
    </div>
  );
}
```

### Async Actions Pattern

```typescript
import { create } from 'zustand';

/**
 * @description Async feature store
 */
export const useAsyncFeatureStore = create<{
  data: Data[] | null;
  isLoading: boolean;
  error: string | null;

  // Actions
  fetchData: () => Promise<void>;
  reset: () => void;
}>((set, get) => ({
  // State
  data: null,
  isLoading: false,
  error: null,

  // Async action
  fetchData: async () => {
    set({ isLoading: true, error: null });

    try {
      const data = await SomeService.fetchData();
      set({ data, isLoading: false });
    } catch (error) {
      set({ error: 'Failed to fetch', isLoading: false });
    }
  },

  // Reset
  reset: () => {
    set({ data: null, isLoading: false, error: null });
  },
}));
```

---

## 📦 Pinia (Vue)

### Store Pattern

```typescript
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';

/**
 * @description Feature store
 */
export const useFeatureStore = defineStore('feature', () => {
  // State
  const isActive = ref<boolean>(false);
  const selectedId = ref<string | null>(null);
  const items = ref<Item[]>([]);

  // Getters
  const hasSelection = computed(() => selectedId.value !== null);
  const itemCount = computed(() => items.value.length);

  // Actions
  const setActive = (active: boolean) => {
    isActive.value = active;
  };

  const setSelectedId = (id: string | null) => {
    selectedId.value = id;
  };

  const addItem = (item: Item) => {
    items.value.push(item);
  };

  const reset = () => {
    isActive.value = false;
    selectedId.value = null;
    items.value = [];
  };

  return {
    // State
    isActive,
    selectedId,
    items,
    // Getters
    hasSelection,
    itemCount,
    // Actions
    setActive,
    setSelectedId,
    addItem,
    reset,
  };
});
```

### Usage in Component

```vue
<script setup lang="ts">
import { useFeatureStore } from '@/stores/feature';

const featureStore = useFeatureStore();

// Access state
console.log(featureStore.isActive);

// Access getters
console.log(featureStore.hasSelection);

// Call actions
featureStore.setActive(true);
</script>

<template>
  <div>
    <button @click="featureStore.setActive(true)">Activate</button>
    <p>Selected: {{ featureStore.selectedId }}</p>
  </div>
</template>
```

---

## 📦 NgRx (Angular)

### Store Pattern

```typescript
import { createReducer, on } from '@ngrx/store';
import { setActive, setSelectedId } from './feature.actions';

/**
 * @description Feature state interface
 */
export interface FeatureState {
  isActive: boolean;
  selectedId: string | null;
}

/**
 * @description Initial state
 */
export const initialState: FeatureState = {
  isActive: false,
  selectedId: null,
};

/**
 * @description Feature reducer
 */
export const featureReducer = createReducer(
  initialState,
  on(setActive, (state, { active }) => ({
    ...state,
    isActive: active,
  })),
  on(setSelectedId, (state, { id }) => ({
    ...state,
    selectedId: id,
  }))
);
```

### Actions Pattern

```typescript
import { createAction, props } from '@ngrx/store');

/**
 * @description Set active action
 */
export const setActive = createAction(
  '[Feature] Set Active',
  props<{ active: boolean }>()
);

/**
 * @description Set selected ID action
 */
export const setSelectedId = createAction(
  '[Feature] Set Selected ID',
  props<{ id: string | null }>()
);
```

### Selectors Pattern

```typescript
import { createFeatureSelector, createSelector } from '@ngrx/store';

/**
 * @description Feature selector
 */
export const selectFeatureState =
  createFeatureSelector<FeatureState>('feature');

/**
 * @description Select isActive
 */
export const selectIsActive = createSelector(
  selectFeatureState,
  (state) => state.isActive
);

/**
 * @description Select selected ID
 */
export const selectSelectedId = createSelector(
  selectFeatureState,
  (state) => state.selectedId
);
```

### Usage in Component

```typescript
import { Store } from '@ngrx/store';
import { selectIsActive, selectSelectedId } from './feature.selectors';
import { setActive, setSelectedId } from './feature.actions';

@Component({
  selector: 'app-feature',
  templateUrl: './feature.component.html',
})
export class FeatureComponent implements OnInit {
  // Select state
  isActive$ = this.store.select(selectIsActive);
  selectedId$ = this.store.select(selectSelectedId);

  constructor(private store: Store) {}

  // Dispatch actions
  handleActivate() {
    this.store.dispatch(setActive({ active: true }));
  }

  handleSelect(id: string) {
    this.store.dispatch(setSelectedId({ id }));
  }
}
```

---

## 🎯 Best Practices

### When to Use What

| Scenario | Solution |
|----------|----------|
| API data | React Query / Vue Query |
| Global UI state | Zustand / Pinia / Redux |
| Form state | React Hook Form / VeeValidate |
| Auth state | Context / Zustand / Pinia |
| Local component state | useState / ref |

### Performance Tips

1. **Select only what you need:**
   ```typescript
   // BAD - Selects entire store
   const state = useFeatureStore();

   // GOOD - Selects specific values
   const isActive = useFeatureStore((state) => state.isActive);
   ```

2. **Use selectors for derived state:**
   ```typescript
   const hasSelection = useAppSelector((state) =>
     state.feature.selectedId !== null
   );
   ```

3. **Memoize expensive computations:**
   ```typescript
   const filteredItems = useMemo(
     () => items.filter((item) => item.active),
     [items]
   );
   ```

---

## 🚨 Mandatory Rules

- ✅ **ALWAYS** use React Query for server state (React)
- ✅ **ALWAYS** use Vue Query for server state (Vue)
- ✅ **ALWAYS** keep store state minimal
- ✅ **ALWAYS** normalize complex data
- ✅ **NEVER** store API data in Redux/Zustand/Pinia (use Query)
- ✅ **NEVER** create deeply nested state structures

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Correct state management solution chosen
- [ ] No API data in client state store
- [ ] Minimal state stored (derive rest)
- [ ] Selectors optimized (avoid unnecessary re-renders)
- [ ] TypeScript types explicit
- [ ] Tests written for actions/selectors

---

**Remember:** Server state (API data) and client state (UI state) are different - use the right tool for each!
