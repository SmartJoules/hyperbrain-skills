---
name: vue-patterns
description: Vue.js development patterns and conventions for DeJoule frontend development. Use when building or reviewing Vue 3 components with the Composition API and following project conventions.
---

# Vue.js Development Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Vue.js patterns and conventions for DeJoule frontend development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL Vue.js development** in DeJoule products:
- Creating new components, composables, plugins
- Implementing features and user stories
- Working with dashboards, charts, forms
- State management and data flow
- Testing Vue code

---

## 🏗️ Vue.js Architecture

### Project Structure (DeJoule Pattern)
```
src/
├── components/         # Reusable UI components
│   ├── ui/            # Basic UI elements (Button, Input, etc.)
│   ├── charts/        # Chart components (ECharts wrappers)
│   └── layout/        # Layout components (Header, Sidebar, etc.)
├── features/          # Feature-specific modules
│   ├── dashboard/     # Dashboard feature
│   │   ├── components/  # Feature components
│   │   ├── composables/ # Feature-specific composables
│   │   ├── services/    # API services
│   │   └── types/       # TypeScript types
│   └── [other features]
├── composables/       # Shared composables
├── services/          # API services
├── stores/            # Pinia stores
├── utils/             # Utility functions
├── types/             # Shared TypeScript types
└── constants/         # App constants
```

---

## 🎨 Component Patterns

### Composition API Pattern (DeJoule Standard)

**ALWAYS follow this structure:**

```vue
<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query';
import { SomeService } from '@/services/some.service';

/**
 * @description Component documentation
 */
interface Props {
  /** The ID of the resource */
  id: string;
}

/**
 * @description Component props
 */
const props = withDefaults(defineProps<Props>(), {
  id: '',
});

/**
 * @description Component emits
 */
interface Emits {
  (e: 'data-loaded', data: DataType): void;
}

const emit = defineEmits<Emits>();

// 1. Reactive state
const localState = ref<string>('');

// 2. Data fetching with Vue Query
const {
  data,
  isLoading,
  isError,
  error,
} = useQuery({
  queryKey: ['feature', props.id],
  queryFn: () => SomeService.fetchData(props.id),
  enabled: computed(() => !!props.id),
  onSuccess: (data) => {
    emit('data-loaded', data);
  },
});

// 3. Mutations
const mutation = useMutation({
  mutationFn: SomeService.updateData,
  onSuccess: () => {
    // Invalidate queries
    queryClient.invalidateQueries(['feature', props.id]);
  },
});

// 4. Computed properties
const title = computed(() => data.value?.title || '');

// 5. Watchers
watch(data, (newData) => {
  if (newData) {
    localState.value = newData.value;
  }
});

// 6. Lifecycle hooks
onMounted(() => {
  console.log('Component mounted');
});

// 7. Methods
const handleUpdate = () => {
  mutation.mutate({ id: props.id, value: localState.value });
};
</script>

<template>
  <div class="feature-container">
    <h2 v-if="isLoading">Loading...</h2>
    <h2 v-else-if="isError">{{ error }}</h2>
    <h2 v-else>{{ title }}</h2>

    <button @click="handleUpdate">Update</button>
  </div>
</template>

<style scoped>
.feature-container {
  padding: 1rem;
}
</style>
```

### Key Component Requirements:
- **ALWAYS** use Composition API with `<script setup>`
- **ALWAYS** use TypeScript with strict mode
- **ALWAYS** define explicit props interfaces
- **ALWAYS** use Vue Query for data fetching
- **ALWAYS** handle loading and error states
- **NEVER** use Options API (use Composition)
- **NEVER** leave any type as `any`

---

## 📡 Composable Patterns

### Data Fetching Composable Pattern

```typescript
import { useQuery, type UseQueryReturn } from '@tanstack/vue-query';
import { SomeService } from '@/services/some.service';

/**
 * @description Composable for fetching feature data
 * @param {string} id - The ID to fetch
 * @returns {UseQueryReturn<DataType, Error>} Query result
 */
export const useFeatureData = (id: MaybeRefOrGetter<string>) => {
  return useQuery({
    queryKey: ['feature', id],
    queryFn: () => SomeService.fetchData(toValue(id)),
    enabled: computed(() => !!toValue(id)),
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 10 * 60 * 1000, // 10 minutes
  });
};
```

### State Management Composable Pattern

```typescript
import { ref, computed } from 'vue';

/**
 * @description Feature state interface
 */
interface FeatureState {
  isActive: boolean;
  value: string;
}

/**
 * @description Composable for managing feature state
 */
export const useFeatureState = () => {
  const state = ref<FeatureState>({
    isActive: false,
    value: '',
  });

  /**
   * @description Update state
   */
  const updateState = (updates: Partial<FeatureState>) => {
    state.value = { ...state.value, ...updates };
  };

  /**
   * @description Reset state
   */
  const resetState = () => {
    state.value = { isActive: false, value: '' };
  };

  /**
   * @description Computed properties
   */
  const isActive = computed(() => state.value.isActive);
  const value = computed(() => state.value.value);

  return {
    state,
    isActive,
    value,
    updateState,
    resetState,
  };
};
```

---

## 🔄 State Management

### Pinia Store Pattern

**ALWAYS use Pinia for global state:**

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

  // Getters
  const hasSelection = computed(() => selectedId.value !== null);

  // Actions
  const setActive = (active: boolean) => {
    isActive.value = active;
  };

  const setSelectedId = (id: string | null) => {
    selectedId.value = id;
  };

  const reset = () => {
    isActive.value = false;
    selectedId.value = null;
  };

  return {
    // State
    isActive,
    selectedId,
    // Getters
    hasSelection,
    // Actions
    setActive,
    setSelectedId,
    reset,
  };
});
```

### Store Usage in Component

```vue
<script setup lang="ts">
import { useFeatureStore } from '@/stores/feature';

const featureStore = useFeatureStore();

// Access state
console.log(featureStore.isActive);

// Call actions
featureStore.setActive(true);
</script>
```

---

## 📊 Chart Integration (Apache ECharts)

### Vue ECharts Component Pattern

```vue
<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue';
import * as echarts from 'echarts';
import type { EChartOption } from 'echarts';

/**
 * @description Props
 */
interface Props {
  option: EChartOption;
  height?: string;
}

const props = withDefaults(defineProps<Props>(), {
  height: '400px',
});

/**
 * @description Chart ref
 */
const chartRef = ref<HTMLDivElement>();
let chartInstance: echarts.ECharts | null = null;

/**
 * @description Initialize chart
 */
const initChart = () => {
  if (!chartRef.value) return;

  chartInstance = echarts.init(chartRef.value);
  chartInstance.setOption(props.option);
};

/**
 * @description Handle resize
 */
const handleResize = () => {
  chartInstance?.resize();
};

onMounted(() => {
  initChart();
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
  chartInstance?.dispose();
});

watch(() => props.option, (newOption) => {
  chartInstance?.setOption(newOption);
});
</script>

<template>
  <div
    ref="chartRef"
    class="chart-container"
    :style="{ height }"
  />
</template>

<style scoped>
.chart-container {
  width: 100%;
}
</style>
```

---

## 🔐 Provide/Inject Pattern

### Site Context Pattern (Similar to Angular ConfigService)

```typescript
import { provide, inject, ref, computed, type InjectionKey } from 'vue';

/**
 * @description Site context type
 */
interface SiteContext {
  currentSite: import('@/types').Site | null;
  setCurrentSite: (site: import('@/types').Site) => void;
}

/**
 * @description Injection key
 */
const SITE_KEY: InjectionKey<SiteContext> = Symbol('site');

/**
 * @description Provide site context
 */
export const provideSite = () => {
  const currentSite = ref<import('@/types').Site | null>(null);

  const setCurrentSite = (site: import('@/types').Site) => {
    currentSite.value = site;
  };

  const context: SiteContext = {
    currentSite: currentSite.value,
    setCurrentSite,
  };

  provide(SITE_KEY, context);

  return context;
};

/**
 * @description Inject site context
 */
export const useSite = () => {
  const context = inject(SITE_KEY);

  if (!context) {
    throw new Error('useSite must be used within provideSite');
  }

  return context;
};
```

---

## 🎯 Data Transformation

### DTO → Domain → ViewModel Pattern

```typescript
// 1. DTO (API Response)
interface EnergyDto {
  timestamp: string;
  kw: number;
  kwh: number;
}

// 2. Domain Model
interface EnergyDomain {
  timestamp: Date;
  power: number;
  energy: number;
}

// 3. ViewModel (UI)
interface EnergyViewModel {
  displayTime: string;
  powerFormatted: string;
  energyFormatted: string;
}

// Transformer
/**
 * @description Energy data transformer
 */
export class EnergyTransformer {
  /**
   * @description Transform DTO to domain model
   */
  static toDomain(dto: EnergyDto): EnergyDomain {
    return {
      timestamp: new Date(dto.timestamp),
      power: dto.kw,
      energy: dto.kwh,
    };
  }

  /**
   * @description Transform domain to view model
   */
  static toViewModel(domain: EnergyDomain): EnergyViewModel {
    return {
      displayTime: domain.timestamp.toLocaleTimeString(),
      powerFormatted: `${domain.power.toFixed(2)} kW`,
      energyFormatted: `${domain.energy.toFixed(2)} kWh`,
    };
  }
}
```

---

## 🚨 Mandatory Rules

### Component Rules
- ✅ **ALWAYS** use Composition API with `<script setup>`
- ✅ **ALWAYS** use TypeScript with strict mode
- ✅ **ALWAYS** define explicit props interfaces
- ✅ **ALWAYS** handle loading and error states
- ✅ **ALWAYS** use Vue Query for server state
- ✅ **NEVER** use Options API
- ✅ **NEVER** use `any` type
- ✅ **NEVER** leave values implicitly typed

### Composable Rules
- ✅ **ALWAYS** name composables with `use` prefix
- ✅ **ALWAYS** define explicit return types
- ✅ **ALWAYS** accept `MaybeRefOrGetter` for reactive parameters
- ✅ **ALWAYS** use `toValue()` to unwrap refs
- ✅ **NEVER** call composables conditionally
- ✅ **NEVER** use composables outside setup

### State Rules
- ✅ **ALWAYS** use Pinia for global state
- ✅ **ALWAYS** use Vue Query for server state
- ✅ **ALWAYS** use composables for local state
- ✅ **NEVER** mix server and client state
- ✅ **NEVER** use Vuex (use Pinia)

### TypeScript Rules
- ✅ **ALWAYS** define explicit interfaces for props
- ✅ **ALWAYS** use generics for reusable composables
- ✅ **ALWAYS** export types when used by other modules
- ✅ **NEVER** use `any` type
- ✅ **NEVER** use implicit `any`

---

## 📝 Naming Conventions

### Component Files
- `PascalCase.vue` - Component file
- `PascalCase.test.ts` - Test file
- `useCamelCase.ts` - Composable file
- `kebab-case.service.ts` - Service file

### Component Names
- PascalCase for components: `FeatureComponent`
- camelCase for composables: `useFeatureData`
- camelCase for utilities: `formatDate`

### File Structure
```
feature/
├── FeatureComponent.vue         # Main component
├── FeatureComponent.test.ts     # Tests
├── useFeatureData.ts            # Composable
├── feature.service.ts           # API service
├── types.ts                     # TypeScript types
└── index.ts                     # Exports
```

---

## 🧪 Testing Patterns

### Component Test Template (Vitest)

```typescript
import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { QueryClient } from '@tanstack/vue-query';
import FeatureComponent from './FeatureComponent.vue';

// Mock API
vi.mock('@/services/some.service');

const mountWithQueryClient = (component: any) => {
  const queryClient = new QueryClient();

  return mount(component, {
    global: {
      plugins: [queryClient],
    },
  });
};

describe('FeatureComponent', () => {
  it('should render loading state', () => {
    const wrapper = mountWithQueryClient(FeatureComponent, {
      props: { id: '123' },
    });

    expect(wrapper.find('.loading').exists()).toBe(true);
  });

  it('should render data after loading', async () => {
    const mockData = { id: '123', title: 'Test' };
    (SomeService.fetchData as any).mockResolvedValue(mockData);

    const wrapper = mountWithQueryClient(FeatureComponent, {
      props: { id: '123' },
    });

    await wrapper.vm.$nextTick();

    expect(wrapper.text()).toContain('Test');
  });

  it('should handle button click', async () => {
    const wrapper = mountWithQueryClient(FeatureComponent, {
      props: { id: '123' },
    });

    await wrapper.find('button').trigger('click');

    expect(mockMutation).toHaveBeenCalled();
  });
});
```

---

## 📋 Common Tasks

### Creating a New Feature Component

```bash
# Create feature directory
mkdir -p src/features/my-feature

# Create files
touch src/features/my-feature/FeatureComponent.vue
touch src/features/my-feature/FeatureComponent.test.ts
touch src/features/my-feature/useFeatureData.ts
touch src/features/my-feature/feature.service.ts
touch src/features/my-feature/types.ts
touch src/features/my-feature/index.ts
```

### Adding Vue Query

```bash
npm install @tanstack/vue-query
```

```typescript
// main.ts
import { VueQueryPlugin } from '@tanstack/vue-query';

app.use(VueQueryPlugin);
```

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Component not re-rendering when data changes**
- **Solution:** Check reactive refs, ensure you're using `ref()` and `computed()` correctly

**Issue: Memory leaks**
- **Solution:** Clean up in `onUnmounted`, remove event listeners

**Issue: TypeScript errors**
- **Solution:** Ensure all types are explicit, no `any` types

**Issue: Chart not rendering**
- **Solution:** Check ECharts options, ensure container has height

---

## 📚 Additional Resources

### Internal Documentation
- DeJoule Vue.js patterns (if available)
- DeJoule API documentation

### External Resources
- Vue.js Documentation: https://vuejs.org
- Vue Query: https://tanstack.com/query/latest/docs/vue/overview
- Pinia: https://pinia.vuejs.org
- TypeScript: https://www.typescriptlang.org
- Apache ECharts: https://echarts.apache.org

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Composition API with `<script setup>` used
- [ ] Explicit TypeScript types
- [ ] No `any` types
- [ ] Vue Query for data fetching
- [ ] Loading and error states handled
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** Consistency over cleverness. Follow these patterns and your code will integrate seamlessly with the DeJoule Vue.js ecosystem.
