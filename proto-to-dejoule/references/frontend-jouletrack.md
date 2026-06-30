# Frontend conventions — JouleTRACK (Angular 15)

How to map a prototype's UI onto JouleTRACK. Confirm structure against the live repo via Morpheus —
**read a recent real feature** rather than trusting docs, because the documented structure and the
actual layout have diverged before.

## Stack (per `src/claude.md` — verify against code)

Angular 15 strict TS/OOP · **PrimeNG** primary UI · **Apache ECharts** (Highcharts is legacy) ·
**NgRx** state · **RxJS 7** (no `setInterval`/`setTimeout`) · CSS with `--n-*` tokens · Work Sans.
Patterns: Container/Presenter, Facade, feature-local services/models where appropriate, Builder for
charts, DI tokens, `OnPush` everywhere, `trackBy`, `takeUntil`/async pipe, Sentry.

> ⚠️ Two NgRx flavors coexist — global `@ngrx/store` (`src/app/reducers`, `actions`) and
> `@ngrx/component-store` (newer features). **Mirror whichever the canonical recent feature uses.**
> Likewise confirm the real folder layout from that feature, not from docs.
> Highcharts and pre-NgRx code paths are **legacy** — present in the repo, never a model to mirror.

## Registration (don't skip)

A feature module nobody can reach isn't shipped. Plan all of:
- **Route**: `src/app/app-routing.module.ts` — lazy `loadChildren` under `:siteId/<feature>`, with
  `canActivate` guards as neighbors use (`AuthGuard`, `RoleGuardService`, `OnPremGuard`,
  `FormDirtyGuard`) and `data.title`. Mirror the `dashboardv2` entry — it's the canonical recent
  feature.
- **Nav/menu entry + role-permission wiring**: locate via Morpheus from the same recent feature
  (which sidebar/menu component and role config it touched) and list the exact files in the plan.

## Feature module plan

- **Mirror the real feature shape** from the chosen recent JouleTRACK example. Prefer feature-local
  `containers/`, `presenters/`, `services/`, and `models/` when the feature owns those concerns.
  Always include the module + routing files. Do **not** prescribe a `/ports` folder as a standard
  structure unless the specific reference feature for this work genuinely uses one.
- **Lazy-loaded module** with its own routing; a **container** component (data + state) hosting
  **presenter** components (pure, `OnPush`, `@Input()`/`@Output()`).
- **Data-access**:
  - **API layer**: use the same level of abstraction as the mirrored feature. Where the repo feature
    uses a real `HttpClient` service plus a mock/testing implementation, follow that; don't invent
    extra indirection just to satisfy a pattern.
  - **NgRx** store + facade (flavor per repo) — replaces any global window object / DOM events.
  - **Typed transformers**: pure functions reshaping API responses; define interfaces in a feature-local
    `models/` folder when the shapes are feature-owned, and reuse `src/app/models` only for existing
    shared domain models. **No `any`.**
  - **Polling** via RxJS: `timer(0, N).pipe(switchMap(() => combineLatest([...])), shareReplay(1))` —
    never `setInterval`. Tear down with `takeUntil`/async pipe.
- **Charts**: ECharts builder classes rendered through **`EchartsWrapperComponent`**
  (`src/app/components/echarts-wrapper/`). It takes `@Input() options` (+ optional `theme`), runs
  `echarts.init` outside the Angular zone, resizes via `ResizeObserver`+`requestAnimationFrame`, and
  disposes in `ngOnDestroy`. Type options with ECharts' TS interfaces.

## Design alignment (delegated)

Do **not** invent colors/type. Use **`JouleTRACK/DESIGN.md`** and the **`sj-ui-design-system`** skill.

- **Tokens**: defined in `src/styles.css` under `:root` as `--n-*`. Map each prototype visual role to a
  real token (e.g. chrome/CTA → `--n-primary-color #072B31`; accent/chart/link → `--n-accent-color
  #28939D`; app background → `--n-screen-bg-color`; body text → fg-1/slate). Comfort/state has its own
  domain tokens (`--in-range` / `--too-warm` / `--too-cold`) — reuse them.
- **Known gaps to flag** (don't silently resolve): no Flame/metric token for numbers; Work Sans vs
  Roboto; partial severity tokens. Surface as reviewer decisions per `DESIGN.md`.
- **Components**: substitute hand-rolled prototype markup with **PrimeNG + repo shared/standalone
  components** so styling/theming is inherited. px → rem, BEM CSS, no fixed-px layout.
- **Fonts**: Work Sans (repo fallback chain `'Work Sans','Roboto',sans-serif`).

## Verification

Run JouleTRACK locally; exercise all views and controls against the new API. Component specs for
transformers/presenters. Confirm no `setInterval`/Promise leaks and that charts dispose on navigation.
**Parity gate**: the new UI's KPIs must match the prototype within rounding before the prototype is
retired.
