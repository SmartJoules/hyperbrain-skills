---
name: react-patterns
description: React development patterns and conventions for DeJoule frontend development. Use when building or reviewing React components, hooks, and state, following the project's conventions.
---

# React Development Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** React patterns and conventions for DeJoule frontend development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL React development** in DeJoule products:
- Creating new components, hooks, contexts
- Implementing features and user stories
- Working with dashboards, charts, forms
- State management and data flow
- Testing React code

---

## 🏗️ React Architecture

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
│   │   ├── hooks/       # Feature-specific hooks
│   │   ├── services/    # API services
│   │   └── types/       # TypeScript types
│   └── [other features]
├── hooks/             # Custom hooks (shared)
├── services/          # API services
├── store/             # State management (Redux/Zustand)
├── utils/             # Utility functions
├── types/             # Shared TypeScript types
└── constants/         # App constants
```

---

## 🎨 Component Patterns

### Functional Component Pattern (DeJoule Standard)

**ALWAYS follow this structure:**

```typescript
import React, { useEffect, useState } from 'react';
import { useQuery, useMutation, UseQueryResult } from '@tanstack/react-query';
import { SomeService } from '@/services/some.service';
import { Button } from '@/components/ui/button';

/**
 * @description Component documentation
 * @example
 * ```tsx
 * <FeatureComponent id="123" />
 * ```
 */
interface FeatureComponentProps {
  /** The ID of the resource */
  id: string;
  /** Optional callback when data loads */
  onDataLoaded?: (data: DataType) => void;
}

/**
 * @description Feature component for displaying X
 */
export const FeatureComponent: React.FC<FeatureComponentProps> = ({
  id,
  onDataLoaded,
}) => {
  // 1. Hooks at the top
  const [localState, setLocalState] = useState<string>('');

  // 2. Data fetching with React Query
  const {
    data,
    isLoading,
    isError,
    error,
  }: UseQueryResult<DataType, Error> = useQuery({
    queryKey: ['feature', id],
    queryFn: () => SomeService.fetchData(id),
    enabled: !!id,
    onSuccess: (data) => {
      onDataLoaded?.(data);
    },
  });

  // 3. Mutations
  const mutation = useMutation({
    mutationFn: SomeService.updateData,
    onSuccess: () => {
      // Invalidate queries
      queryClient.invalidateQueries(['feature', id]);
    },
  });

  // 4. Effects for side effects
  useEffect(() => {
    if (data) {
      setLocalState(data.value);
    }
  }, [data]);

  // 5. Early returns for loading/error states
  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (isError) {
    return <ErrorMessage error={error} />;
  }

  // 6. Render
  return (
    <div className="feature-container">
      <h2>Feature: {data?.title}</h2>
      <Button onClick={() => mutation.mutate({ id, value: localState })}>
        Update
      </Button>
    </div>
  );
};

// 7. Display name for debugging
FeatureComponent.displayName = 'FeatureComponent';
```

### Key Component Requirements:
- **ALWAYS** use functional components with TypeScript
- **ALWAYS** define explicit props interfaces
- **ALWAYS** use React Query for data fetching
- **ALWAYS** handle loading and error states
- **ALWAYS** set displayName for debugging
- **NEVER** use class components (use functional)
- **NEVER** leave any type as `any`

---

## 📡 Custom Hooks Patterns

### Data Fetching Hook Pattern

```typescript
import { useQuery, UseQueryResult } from '@tanstack/react-query';
import { SomeService } from '@/services/some.service';

/**
 * @description Hook for fetching feature data
 * @param {string} id - The ID to fetch
 * @returns {UseQueryResult<DataType, Error>} Query result
 */
export const useFeatureData = (
  id: string
): UseQueryResult<DataType, Error> => {
  return useQuery({
    queryKey: ['feature', id],
    queryFn: () => SomeService.fetchData(id),
    enabled: !!id,
    staleTime: 5 * 60 * 1000, // 5 minutes
    cacheTime: 10 * 60 * 1000, // 10 minutes
  });
};
```

### State Management Hook Pattern

```typescript
import { useState, useCallback } from 'react';

/**
 * @description Hook for managing feature state
 */
export const useFeatureState = () => {
  const [state, setState] = useState<FeatureState>({
    isActive: false,
    value: '',
  });

  const updateState = useCallback((updates: Partial<FeatureState>) => {
    setState((prev) => ({ ...prev, ...updates }));
  }, []);

  const resetState = useCallback(() => {
    setState({ isActive: false, value: '' });
  }, []);

  return {
    state,
    updateState,
    resetState,
  };
};
```

---

## 🔄 State Management

### React Query (TanStack Query) Pattern

**ALWAYS use React Query for server state:**

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// Query for data fetching
const { data, isLoading, error } = useQuery({
  queryKey: ['resource', id],
  queryFn: () => apiService.getResource(id),
  enabled: !!id,
});

// Mutation for updates
const queryClient = useQueryClient();

const mutation = useMutation({
  mutationFn: (data: UpdateType) => apiService.updateResource(data),
  onSuccess: () => {
    // Invalidate and refetch
    queryClient.invalidateQueries(['resource']);
  },
  onError: (error) => {
    console.error('Update failed:', error);
  },
});
```

### Zustand for Client State (Optional)

```typescript
import { create } from 'zustand';

interface FeatureStore {
  // State
  isActive: boolean;
  selectedId: string | null;

  // Actions
  setActive: (active: boolean) => void;
  setSelectedId: (id: string | null) => void;
}

export const useFeatureStore = create<FeatureStore>((set) => ({
  isActive: false,
  selectedId: null,

  setActive: (active) => set({ isActive: active }),
  setSelectedId: (id) => set({ selectedId: id }),
}));
```

---

## 📊 Chart Integration (Apache ECharts)

### React ECharts Component Pattern

```typescript
import React, { useRef, useEffect } from 'react';
import * as echarts from 'echarts';
import { EChartOption } from 'echarts';

/**
 * @description Props for ChartComponent
 */
interface ChartComponentProps {
  /** Chart options */
  option: EChartOption;
  /** CSS class name */
  className?: string;
  /** Chart height */
  height?: string;
}

/**
 * @description ECharts component wrapper
 */
export const ChartComponent: React.FC<ChartComponentProps> = ({
  option,
  className = '',
  height = '400px',
}) => {
  const chartRef = useRef<HTMLDivElement>(null);
  const chartInstance = useRef<echarts.ECharts | null>(null);

  useEffect(() => {
    if (chartRef.current) {
      chartInstance.current = echarts.init(chartRef.current);
    }

    return () => {
      chartInstance.current?.dispose();
    };
  }, []);

  useEffect(() => {
    if (chartInstance.current) {
      chartInstance.current.setOption(option);
    }
  }, [option]);

  useEffect(() => {
    const handleResize = () => {
      chartInstance.current?.resize();
    };

    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, []);

  return (
    <div
      ref={chartRef}
      className={className}
      style={{ width: '100%', height }}
    />
  );
};
```

---

## 🔐 Context Handling

### Site Context Pattern (Similar to Angular ConfigService)

```typescript
import React, { createContext, useContext, useState, ReactNode } from 'react';

/**
 * @description Site context type
 */
interface SiteContextType {
  currentSite: Site | null;
  setCurrentSite: (site: Site) => void;
}

/**
 * @description Site context
 */
const SiteContext = createContext<SiteContextType | undefined>(undefined);

/**
 * @description Site provider props
 */
interface SiteProviderProps {
  children: ReactNode;
}

/**
 * @description Site context provider
 */
export const SiteProvider: React.FC<SiteProviderProps> = ({ children }) => {
  const [currentSite, setCurrentSite] = useState<Site | null>(null);

  return (
    <SiteContext.Provider value={{ currentSite, setCurrentSite }}>
      {children}
    </SiteContext.Provider>
  );
};

/**
 * @description Hook to use site context
 */
export const useSite = (): SiteContextType => {
  const context = useContext(SiteContext);
  if (!context) {
    throw new Error('useSite must be used within SiteProvider');
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
- ✅ **ALWAYS** use functional components with TypeScript
- ✅ **ALWAYS** define explicit props interfaces
- ✅ **ALWAYS** handle loading and error states
- ✅ **ALWAYS** set displayName for debugging
- ✅ **ALWAYS** use React Query for server state
- ✅ **NEVER** use class components
- ✅ **NEVER** use `any` type
- ✅ **NEVER** leave values implicitly typed

### Hook Rules
- ✅ **ALWAYS** name hooks with `use` prefix
- ✅ **ALWAYS** define explicit return types
- ✅ **ALWAYS** document hook purpose
- ✅ **NEVER** call hooks conditionally
- ✅ **NEVER** use hooks outside functions

### State Rules
- ✅ **ALWAYS** use React Query for server state
- ✅ **ALWAYS** invalidate queries after mutations
- ✅ **ALWAYS** use Zustand/Jotai for client state (if needed)
- ✅ **NEVER** mix server and client state
- ✅ **NEVER** use Redux for simple cases

### TypeScript Rules
- ✅ **ALWAYS** define explicit interfaces for props
- ✅ **ALWAYS** use generics for reusable hooks
- ✅ **ALWAYS** export types when used by other modules
- ✅ **NEVER** use `any` type
- ✅ **NEVER** use implicit `any`

---

## 📝 Naming Conventions

### Component Files
- `PascalCase.tsx` - Component file
- `PascalCase.test.tsx` - Test file
- `useCamelCase.ts` - Hook file
- `kebab-case.service.ts` - Service file

### Component Names
- PascalCase for components: `FeatureComponent`
- camelCase for hooks: `useFeatureData`
- camelCase for utilities: `formatDate`

### File Structure
```
feature/
├── FeatureComponent.tsx       # Main component
├── FeatureComponent.test.tsx  # Tests
├── useFeatureData.ts          # Custom hook
├── feature.service.ts         # API service
├── types.ts                   # TypeScript types
└── index.ts                   # Exports
```

---

## 🧪 Testing Patterns

### Component Test Template (React Testing Library)

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { FeatureComponent } from './FeatureComponent';

// Mock API
jest.mock('@/services/some.service');

const renderWithQueryClient = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      {component}
    </QueryClientProvider>
  );
};

describe('FeatureComponent', () => {
  it('should render loading state', () => {
    renderWithQueryClient(<FeatureComponent id="123" />);
    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('should render data after loading', async () => {
    const mockData = { id: '123', title: 'Test' };
    (SomeService.fetchData as jest.Mock).mockResolvedValue(mockData);

    renderWithQueryClient(<FeatureComponent id="123" />);

    await waitFor(() => {
      expect(screen.getByText('Test')).toBeInTheDocument();
    });
  });

  it('should handle button click', async () => {
    const user = userEvent.setup();
    renderWithQueryClient(<FeatureComponent id="123" />);

    const button = screen.getByRole('button');
    await user.click(button);

    expect(mockMutation).toHaveBeenCalled();
  });
});
```

---

## 📋 Common Tasks

### Creating a New Feature Component

```bash
# Generate component (if using a generator)
npm run generate:component MyFeature

# Or create manually
mkdir -p src/features/my-feature
touch src/features/my-feature/MyFeatureComponent.tsx
touch src/features/my-feature/MyFeatureComponent.test.tsx
touch src/features/my-feature/useMyFeatureData.ts
touch src/features/my-feature/myFeature.service.ts
touch src/features/my-feature/types.ts
touch src/features/my-feature/index.ts
```

### Adding React Query

```bash
npm install @tanstack/react-query
```

```typescript
// Wrap app with QueryClientProvider
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
    </QueryClientProvider>
  );
}
```

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Component not re-rendering when data changes**
- **Solution:** Check React Query queryKey, ensure it's unique and dependencies are correct

**Issue: Memory leaks**
- **Solution:** Clean up useEffect, remove event listeners

**Issue: TypeScript errors**
- **Solution:** Ensure all types are explicit, no `any` types

**Issue: Chart not rendering**
- **Solution:** Check ECharts options, ensure container has height

---

## 📚 Additional Resources

### Internal Documentation
- DeJoule React patterns (if available)
- DeJoule API documentation

### External Resources
- React Documentation: https://react.dev
- React Query: https://tanstack.com/query/latest
- TypeScript: https://www.typescriptlang.org
- Apache ECharts: https://echarts.apache.org

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Functional component used
- [ ] Explicit TypeScript types
- [ ] No `any` types
- [ ] React Query for data fetching
- [ ] Loading and error states handled
- [ ] displayName set
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** Consistency over cleverness. Follow these patterns and your code will integrate seamlessly with the DeJoule React ecosystem.
