---
name: nextjs-patterns
description: Next.js development patterns and conventions for DeJoule web applications. Use when building or reviewing Next.js apps, including routing, data fetching, server components, and API routes.
---

# Next.js Development Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Next.js patterns and conventions for DeJoule web applications
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL Next.js development** in DeJoule products:
- Creating new pages, layouts, and components
- Implementing SSR/SSG for performance
- Building API routes
- Working with dashboards, charts, forms
- Server and client components

---

## 🏗️ Next.js Architecture

### Project Structure (App Router - DeJoule Pattern)
```
src/
├── app/                    # App Router pages
│   ├── (auth)/           # Auth group
│   │   ├── login/
│   │   └── layout.tsx
│   ├── (dashboard)/      # Dashboard group
│   │   ├── dashboard/
│   │   ├── analytics/
│   │   └── layout.tsx
│   ├── api/             # API routes
│   │   ├── health/
│   │   └── trpc/
│   ├── layout.tsx       # Root layout
│   └── page.tsx         # Home page
├── components/           # Shared components
│   ├── ui/              # UI components
│   ├── charts/          # Chart components
│   └── forms/           # Form components
├── lib/                 # Utilities
│   ├── db.ts           # Database client
│   ├── auth.ts         # Auth utilities
│   └── utils.ts        # General utilities
├── server/              # Server-only code
│   ├── services/       # API services
│   └── repositories/   # Data access
└── types/              # Shared types
```

---

## 🎨 Page Patterns

### Server Component Pattern (Default)

**ALWAYS use Server Components by default:**

```typescript
import { SomeService } from '@/server/services/some.service';
import { ClientComponent } from '@/components/ClientComponent';

/**
 * @description Dashboard page props
 */
interface DashboardPageProps {
  searchParams: {
    site?: string;
  };
}

/**
 * @description Dashboard page (Server Component)
 */
export default async function DashboardPage({
  searchParams,
}: DashboardPageProps) {
  // 1. Fetch data on server
  const data = await SomeService.fetchData(searchParams.site);

  // 2. Server-side rendering
  return (
    <div className="dashboard-container">
      <h1>Dashboard</h1>

      {/* Pass data to client components */}
      <ClientComponent initialData={data} />
    </div>
  );
}
```

### Client Component Pattern

**USE Client Components ONLY when needed:**

```typescript
'use client';

import { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';

/**
 * @description Client component for interactive features
 */
export function ClientComponent({
  initialData,
}: {
  initialData: DataType;
}) {
  const [state, setState] = useState(initialData);

  // Client-side data fetching
  const { data } = useQuery({
    queryKey: ['feature'],
    queryFn: () => fetch('/api/data').then((res) => res.json()),
    initialData,
  });

  return (
    <div>
      <h2>{state.title}</h2>
      {/* Interactive UI */}
    </div>
  );
}
```

---

## 📡 API Routes

### Route Handler Pattern (App Router)

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { SomeService } from '@/server/services/some.service';
import { z } from 'zod';

/**
 * @description Request schema
 */
const requestSchema = z.object({
  siteId: z.string(),
  startDate: z.string().datetime(),
  endDate: z.string().datetime(),
});

/**
 * @description GET handler
 */
export async function GET(request: NextRequest) {
  try {
    // 1. Parse and validate input
    const searchParams = request.nextUrl.searchParams;
    const params = Object.fromEntries(searchParams);

    const validatedParams = requestSchema.parse(params);

    // 2. Fetch data
    const data = await SomeService.fetchData(validatedParams);

    // 3. Return response
    return NextResponse.json({
      success: true,
      data,
    });
  } catch (error) {
    // 4. Handle errors
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        {
          success: false,
          error: 'Invalid parameters',
          details: error.errors,
        },
        { status: 400 }
      );
    }

    return NextResponse.json(
      {
        success: false,
        error: 'Internal server error',
      },
      { status: 500 }
    );
  }
}

/**
 * @description POST handler
 */
export async function POST(request: NextRequest) {
  try {
    // 1. Parse request body
    const body = await request.json();

    // 2. Validate
    const validatedBody = requestSchema.parse(body);

    // 3. Process
    const result = await SomeService.createData(validatedBody);

    // 4. Return response
    return NextResponse.json(
      {
        success: true,
        data: result,
      },
      { status: 201 }
    );
  } catch (error) {
    return NextResponse.json(
      {
        success: false,
        error: 'Invalid request',
      },
      { status: 400 }
    );
  }
}
```

---

## 🔄 Data Fetching

### Server-Side Data Fetching

```typescript
import { SomeService } from '@/server/services/some.service';

/**
 * @description Fetch data on server
 */
export async function ServerDataComponent({
  id,
}: {
  id: string;
}) {
  // Direct server-side fetch
  const data = await SomeService.fetchData(id);

  return (
    <div>
      <h1>{data.title}</h1>
      <p>{data.description}</p>
    </div>
  );
}
```

### Client-Side Data Fetching

```typescript
'use client';

import { useQuery } from '@tanstack/react-query';

/**
 * @description Client-side data fetching
 */
export function ClientDataComponent({ id }: { id: string }) {
  const { data, isLoading, error } = useQuery({
    queryKey: ['feature', id],
    queryFn: async () => {
      const res = await fetch(`/api/data/${id}`);
      return res.json();
    },
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <h1>{data?.title}</h1>
    </div>
  );
}
```

### Hybrid Approach (Recommended)

```typescript
import { HydrationBoundary, dehydrate } from '@tanstack/react-query';
import { getQueryClient } from '@/lib/query-client';
import { ClientComponent } from '@/components/ClientComponent';

/**
 * @description Page with SSR data + client interactivity
 */
export default async function HybridPage({
  params,
}: {
  params: { id: string };
}) {
  const queryClient = getQueryClient();

  // Pre-fetch data on server
  await queryClient.prefetchQuery({
    queryKey: ['feature', params.id],
    queryFn: () => fetch(`/api/data/${params.id}`).then((res) => res.json()),
  });

  // Hydrate on client
  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <ClientComponent id={params.id} />
    </HydrationBoundary>
  );
}
```

---

## 📊 Chart Integration (Apache ECharts)

### Server Component Chart

```typescript
import * as echarts from 'echarts';
import { EChartsReact } from 'echarts-react-wrapper';
import type { EChartOption } from 'echarts';

/**
 * @description Props for chart
 */
interface ChartProps {
  data: {
    timestamps: string[];
    values: number[];
  };
}

/**
 * @description Server-side chart component
 */
export function ServerChart({ data }: ChartProps) {
  const option: EChartOption = {
    xAxis: {
      type: 'category',
      data: data.timestamps,
    },
    yAxis: {
      type: 'value',
    },
    series: [
      {
        type: 'line',
        data: data.values,
      },
    ],
  };

  return (
    <div style={{ width: '100%', height: '400px' }}>
      <EChartsReact option={option} />
    </div>
  );
}
```

---

## 🔐 Authentication

### Middleware Pattern

```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { verifyToken } from '@/lib/auth';

/**
 * @description Middleware for auth check
 */
export function middleware(request: NextRequest) {
  // 1. Get token from cookies
  const token = request.cookies.get('auth-token')?.value;

  // 2. Verify token
  if (!token || !verifyToken(token)) {
    // Redirect to login
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // 3. Continue
  return NextResponse.next();
}

/**
 * @description Middleware config
 */
export const config = {
  matcher: ['/dashboard/:path*', '/api/protected/:path*'],
};
```

### Server Actions Pattern (App Router)

```typescript
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';

/**
 * @description Action schema
 */
const actionSchema = z.object({
  siteId: z.string(),
  value: z.number(),
});

/**
 * @description Server action
 */
export async function updateSiteAction(formData: FormData) {
  // 1. Validate
  const data = actionSchema.parse({
    siteId: formData.get('siteId'),
    value: Number(formData.get('value')),
  });

  // 2. Process
  await SomeService.updateSite(data);

  // 3. Revalidate
  revalidatePath('/dashboard');

  // 4. Return
  return { success: true };
}
```

---

## 🎯 Data Transformation

### Server-Side Transformer Pattern

```typescript
import { EnergyTransformer } from '@/server/transformers/energy.transformer';

/**
 * @description API route with transformation
 */
export async function GET(request: NextRequest) {
  // 1. Fetch DTO from database/API
  const dtos = await SomeService.fetchRawData();

  // 2. Transform to domain models
  const domainModels = dtos.map((dto) =>
    EnergyTransformer.toDomain(dto)
  );

  // 3. Transform to view models
  const viewModels = domainModels.map((domain) =>
    EnergyTransformer.toViewModel(domain)
  );

  // 4. Return
  return NextResponse.json({
    success: true,
    data: viewModels,
  });
}
```

---

## 🚨 Mandatory Rules

### Page/Component Rules
- ✅ **ALWAYS** use Server Components by default
- ✅ **ALWAYS** add `'use client'` only when needed
- ✅ **ALWAYS** use TypeScript with strict mode
- ✅ **ALWAYS** define explicit props interfaces
- ✅ **NEVER** fetch data in client component if server can do it
- ✅ **NEVER** use `any` type

### API Route Rules
- ✅ **ALWAYS** validate input with Zod
- ✅ **ALWAYS** handle errors properly
- ✅ **ALWAYS** return proper HTTP status codes
- ✅ **ALWAYS** use typed responses
- ✅ **NEVER** trust client input

### Performance Rules
- ✅ **ALWAYS** use SSG for static content
- ✅ **ALWAYS** use SSR for dynamic content
- ✅ **ALWAYS** use ISR for content that updates periodically
- ✅ **ALWAYS** prefetch data when possible
- ✅ **NEVER** fetch same data multiple times

---

## 📝 Naming Conventions

### File Names
- `page.tsx` - Page file
- `layout.tsx` - Layout file
- `loading.tsx` - Loading state
- `error.tsx` - Error boundary
- `route.ts` - API route

### Component Names
- PascalCase for components: `DashboardComponent`
- camelCase for utilities: `formatDate`
- kebab-case for files: `dashboard-page.tsx`

---

## 🧪 Testing Patterns

### Page Test Template

```typescript
import { render, screen } from '@testing-library/react';
import DashboardPage from './page';

// Mock server action
vi.mock('@/actions/dashboard', () => ({
  getDashboardData: vi.fn(() => Promise.resolve({ data: 'test' })),
}));

describe('DashboardPage', () => {
  it('should render dashboard', async () => {
    const page = await DashboardPage({
      searchParams: { site: 'test' },
    });

    render(page);

    expect(screen.getByText('Dashboard')).toBeInTheDocument();
  });
});
```

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Server component can't use hooks**
- **Solution:** Move hooks to client component, pass data as props

**Issue: Data not updating**
- **Solution:** Use `revalidatePath` or `revalidateTag` after mutations

**Issue: Client component on initial render**
- **Solution:** Add `'use client'` directive at top of file

---

## 📚 Additional Resources

### External Resources
- Next.js Documentation: https://nextjs.org/docs
- React Query: https://tanstack.com/query/latest
- Zod: https://zod.dev
- TypeScript: https://www.typescriptlang.org

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Server components used by default
- [ ] Explicit TypeScript types
- [ ] No `any` types
- [ ] Input validation on API routes
- [ ] Error handling implemented
- [ ] Performance optimized (SSG/SSR/ISR)
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** Next.js defaults to Server Components - only use Client Components when you need interactivity or browser APIs.
