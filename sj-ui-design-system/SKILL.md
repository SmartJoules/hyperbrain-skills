---
name: sj-ui-design-system
description: >
  SmartJoules / JouleTRACK frontend design system reference for the dejoule-v4 Angular 15 app.
  Covers PrimeNG-first component selection, Boxicons-first icon selection, design tokens,
  accessibility, data resilience, Highcharts charting,
  and Impeccable design quality integration. Triggers on UI component questions, styling, forms,
  tables, charts, accessibility, loading states, error handling, empty states, keyboard navigation,
  focus management, and design review. Also covers NgRx patterns, status colours, typography,
  or "how do I add X to this module". Always consult this skill before suggesting any new
  npm package for UI purposes.
---

# SmartJoules UI Design System

This skill documents the **actual** design system of the JouleTRACK frontend (`dejoule-v4`),
grounded in the real codebase. Use it to give correct, on-brand answers without hallucinating
generic Angular or PrimeNG patterns.

---

## 1. Stack at a Glance

| Layer | Technology | Version |
|---|---|---|
| Framework | Angular | 15.x |
| Primary component lib for new UI | PrimeNG | 15.4.1 |
| Secondary/legacy component lib | Angular Material | 15.2.9 |
| State management | NgRx Store + Component-Store | 15.x |
| Charts / data viz | Highcharts + D3 | v6 / v5 |
| Date picker | @danielmoncada/angular-datetime-picker | 15.x |
| Font | Work Sans (+ Roboto fallback) | — |
| Icons for new UI | Boxicons | use existing setup or scoped `@boxicons/*` packages |
| Legacy icons | Material Symbols Rounded / PrimeIcons | preserve only where already embedded in existing components |
| Error tracking | Sentry Angular | 7.x |

---

## 2. Design Tokens — CSS Custom Properties

These are defined in `src/styles.css` under `:root`. Always use these variables. Never hardcode hex values.

### Colour palette
```css
/* Brand */
--n-primary-color: #072B31;          /* Dark teal — headers, nav, primary actions */
--n-primary-color-rgb: rgba(7, 43, 49, 1);
--n-primary-color-a15: rgba(7, 43, 49, 0.15);
--n-primary-color-a05: rgba(7, 43, 49, 0.05);
--n-accent-color: #28939D;           /* Mid teal — highlights, links, active states */

/* System status colours */
--n-sys-red: #FF0F00;                /* Error, offline, critical */
--n-sys-orange: #FF9900;             /* Warning, sync-available, medium severity */
--n-sys-green: #228B22;              /* Success, online, synced */

/* Neutrals */
--n-screen-bg-color: #f6f6f6;        /* Page background */
--n-white: #FFF;
--n-black: #1A1A1A;
--n-border-color: #E8E8E8;
--n-highlight-color: #F5F6FB;
--n-primary-title-color: rgba(0, 0, 0, 0.6);
--n-primary-shadow: 0 4px 15px rgba(189, 189, 189, 0.25);
--n-primary-shadow-soft: 0 4px 15px #e6ecf6;

/* PrimeNG overrides (also in :root) */
--primary-color: #072B31;
--primary-500: #f90;
```

### Typography and Icons
- **Font family**: `'Work Sans', 'Roboto', sans-serif` — set globally on body
- **New icons**: use Boxicons for product, action, navigation, status, and feature icons.
  Keep icons as `currentColor`, size them consistently with the component, and add accessible labels/tooltips for icon-only controls.
- **Legacy icons**: Material Symbols and PrimeIcons may remain in existing components, but do not introduce them in new UI when Boxicons can cover the need.

### Global utility classes (from styles.css)
```css
/* Flex helpers */
.flex-block    /* display:flex, font-size:14px */
.flex-h        /* flex-direction: row */
.flex-v        /* flex-direction: column */
.align-center  /* align-items: center */
.flex-space-btw /* space-between + gap:5px */

/* Gap scale */
.gap-4  .gap-8  .gap-12  .gap-16  .gap-24

/* Text */
.text-ellipsis     /* truncate with ellipsis */
.text-align-left / .text-align-center

/* Pointer */
.c-pointer         /* cursor: pointer */
.pointer-events-none

/* Animation */
.rotate-180        /* rotates an icon 180deg (chevrons) */
.dd-icon           /* transition: transform 200ms */
```

---

## 3. Component Decision Tree

When a developer asks "which component should I use for X", follow this decision tree:

### Global component rule

PrimeNG is the default component library for new UI surfaces. Use repo-standard internal wrappers where they exist (`app-button`, `png-table`, `severity-chips`, `segment-toggle-switch`), because those wrappers encode SmartJoules styling and behavior. Use Angular Material only for legacy surfaces or specific components already standardized by this design system.

### Icon rule

Use Boxicons for new icons. Verify the icon name exists, keep color as `currentColor`, do not mix icon libraries in one new surface, and ensure icon-only actions have `aria-label` plus tooltip text.

### Data tables — ENFORCED RULE (non-negotiable)

> ⛔ **ABSOLUTE**: Every data grid/table in JouleTRACK MUST use PrimeNG `p-table`. Angular Material
> `mat-table` is NEVER used for data grids. This is enforced across the entire codebase.
> When generating any table code, output `p-table` immediately — never suggest `mat-table`.

**Three tiers — pick the right one:**

**Tier 1 — Simple read-only list** (no filters, no row actions):
Use `p-table` directly with `pTemplate="header"` + `pTemplate="body"`.

**Tier 2 — Interactive list with column filters** (most common, matches screenshots):
Use `p-table` with `[filterDelay]="0"` and **inline `p-columnFilter` inside each `<th>`**.
Filters render as a second `<tr>` inside `<ng-template pTemplate="header">`.
This is the exact pattern from `png-table.component.html` and Image 2 (customer list).

```html
<!-- ✅ CORRECT — inline column filters in header (Image 2 pattern) -->
<p-table [value]="data" [globalFilterFields]="['name','status']"
         dataKey="id" [filterDelay]="0"
         styleClass="my-feature-tbl" [scrollable]="true" scrollHeight="flex">

  <ng-template pTemplate="header">
    <!-- Row 1: column labels + sort icons -->
    <tr>
      <th pSortableColumn="name">Name <p-sortIcon field="name"></p-sortIcon></th>
      <th pSortableColumn="status">Status <p-sortIcon field="status"></p-sortIcon></th>
    </tr>
    <!-- Row 2: inline filter inputs (always the row directly below headers) -->
    <tr>
      <th>
        <p-columnFilter type="text" field="name" [showMenu]="false"
                        placeholder="Type to search" matchMode="contains">
        </p-columnFilter>
      </th>
      <th>
        <!-- Dropdown filter for enum/status columns -->
        <p-columnFilter field="status" matchMode="in"
                        [showMatchModes]="false" [showOperator]="false"
                        [showAddButton]="false" display="menu" [showMenu]="true">
          <ng-template pTemplate="filter" let-value let-filter="filterCallback">
            <p-multiSelect [ngModel]="value"
                           [options]="statusOptions"
                           optionLabel="label" optionValue="value"
                           placeholder="Select One"
                           (onChange)="filter($event.value)">
            </p-multiSelect>
          </ng-template>
        </p-columnFilter>
      </th>
    </tr>
  </ng-template>

  <ng-template pTemplate="body" let-row>
    <tr>
      <td>{{ row.name }}</td>
      <td>{{ row.status }}</td>
    </tr>
  </ng-template>
</p-table>
```

**Tier 3 — Row expand / master-detail** (matches Image 1 — product → orders nested table):
Use `p-table` with `[dataKey]="'id'"` and `pRowExpander` + `pTemplate="rowexpansion"`.

```html
<!-- ✅ CORRECT — row expand pattern (Image 1 pattern) -->
<p-table [value]="products" dataKey="id" [expandedRowKeys]="expandedRows"
         styleClass="my-feature-tbl" [scrollable]="true">

  <ng-template pTemplate="header">
    <tr>
      <th style="width:3rem"></th>   <!-- expand chevron column -->
      <th>Name</th>
      <th>Price</th>
      <th>Status</th>
    </tr>
  </ng-template>

  <ng-template pTemplate="body" let-row let-expanded="expanded">
    <tr>
      <td>
        <button type="button" pButton pRipple [pRowToggler]="row"
                class="p-button-text p-button-rounded p-button-plain"
                [icon]="expanded ? 'pi pi-chevron-down' : 'pi pi-chevron-right'">
        </button>
      </td>
      <td>{{ row.name }}</td>
      <td>{{ row.price | currency }}</td>
      <td><span class="status-chip">{{ row.status }}</span></td>
    </tr>
  </ng-template>

  <!-- Nested table inside expanded row -->
  <ng-template pTemplate="rowexpansion" let-row>
    <tr>
      <td colspan="4">
        <div class="p-3">
          <h6 style="font-weight:600;margin-bottom:12px">Orders for {{ row.name }}</h6>
          <p-table [value]="row.orders" styleClass="inner-tbl">
            <ng-template pTemplate="header">
              <tr>
                <th pSortableColumn="id">Id <p-sortIcon field="id"></p-sortIcon></th>
                <th pSortableColumn="customer">Customer <p-sortIcon field="customer"></p-sortIcon></th>
                <th pSortableColumn="date">Date <p-sortIcon field="date"></p-sortIcon></th>
                <th pSortableColumn="amount">Amount <p-sortIcon field="amount"></p-sortIcon></th>
                <th pSortableColumn="status">Status <p-sortIcon field="status"></p-sortIcon></th>
              </tr>
            </ng-template>
            <ng-template pTemplate="body" let-order>
              <tr>
                <td>{{ order.id }}</td>
                <td>{{ order.customer }}</td>
                <td>{{ order.date }}</td>
                <td>{{ order.amount | currency }}</td>
                <td><span class="order-status-chip chip-{{ order.status | lowercase }}">{{ order.status }}</span></td>
              </tr>
            </ng-template>
          </p-table>
        </div>
      </td>
    </tr>
  </ng-template>
</p-table>
```

**Tier 4 — Complex table with lazy load, CSV, bulk actions** (controller list page):
→ Use the internal `<png-table>` component. See §4 for its API.

### Dropdowns / selects
- Simple select with Material form field look → `smart-dropdown` (internal component, uses `MatSelect`)
- Complex dropdown with search → `DropdownModule` from PrimeNG (`p-dropdown`)
- Template / component selector (small list, no search) → `template-dropdown` (internal)
- Multi-level / nested options → `smart-nested-dropdown` (internal)

### Date / time pickers
→ **Always use `@danielmoncada/angular-datetime-picker`**. Never install a new date library.
Import: `OwlDateTimeModule, OwlNativeDateTimeModule` from `@danielmoncada/angular-datetime-picker`

### Dialogs / modals
→ Angular Material `MatDialog`. Import `MatLegacyDialogModule as MatDialogModule` (pending legacy migration).

### Tooltips
→ PrimeNG `TooltipModule` (`pTooltip` directive). Do not use MatTooltip for new code.

### Skeleton / loading states
→ PrimeNG `SkeletonModule` (`p-skeleton`).

### Toggle / switch (binary on/off)
→ Angular Material `MatSlideToggleModule`. The theme for toggles uses a custom green palette:
  `#6fdc63` (100), `#0f9f05` (500), `#0b7304` (700).

### Segmented toggle (active/inactive tabs)
→ Internal `<segment-toggle-switch>` component.

### Alert severity badges
→ Internal `<severity-chips>` component. Use `[severity]` input with values: `low | medium | high | critical`.

### Chips / tags
→ PrimeNG `ChipModule` for generic chips. Use `<severity-chips>` for alert severity specifically.

### Forms
→ Angular `ReactiveFormsModule` + `MatFormField` + `MatInput`. Always use reactive forms, not template-driven.

### Notifications / snackbar
→ `rapidPlantBuilderService.displaySnackbarMessage(message)` — the internal snackbar utility.

### PDF viewer
→ `ng2-pdf-viewer` (already in package).

### Colour picker
→ `ngx-colors` (already in package).

### Code editor (monaco)
→ `ngx-monaco-editor` (already in package).

---

## 4. Internal Reusable Components

These are **production components** already in the codebase. Import and use them — never recreate.

### `<png-table>` — Feature-rich data table
**Path**: `src/app/app/standalone-components/reusable-components/png-components/png-table/`
**Selector**: `png-table`
**Standalone**: Yes
**Import from**: `PngTableComponent` (direct import, standalone)

```typescript
// Key @Inputs
@Input() columns: { field: string; header: string }[] = [];
@Input() data: any[] = [];
@Input() sortableColumns: string[] = [];
@Input() filterableColumns: string[] = [];
@Input() pagination: boolean = false;
@Input() rowsPerPageOptions: number[] = [15, 30, 50, 100];
@Input() totalRecords: number = 0;
@Input() isTableLoading: boolean = false;
@Input() isSyncLoading: boolean = false;
@Input() isUpdateProgressLoading: boolean = false;
@Input() siteId: any;

// Key @Outputs
@Output() tableConfig = new EventEmitter();       // lazy load / pagination events
@Output() refreshStatus = new EventEmitter();
@Output() syncConfig = new EventEmitter();
@Output() bulkUpdateControllers = new EventEmitter();
@Output() openControllerApp = new EventEmitter();
```

**Status colour helper** (internal, can reference pattern):
```typescript
// configstatus: '0' = Synced (#228B22), '1' = Sync Available (#FF9900), '2' = Sync Failed (#FF0F00)
getConfigStatusColor(configstatus): string {
  if (configstatus == '0') return 'var(--n-sys-green)';
  if (configstatus == '1') return 'var(--n-sys-orange)';
  if (configstatus == '2') return 'var(--n-sys-red)';
  return '#7A7A7A';
}
```

---

### `<severity-chips>` — Alert severity badge
**Path**: `src/app/app/standalone-components/reusable-components/severity-chips/`
**Selector**: `severity-chips`
**Standalone**: Yes

```typescript
@Input() severity: string = 'low';        // 'low' | 'medium' | 'high' | 'critical'
@Input() showFirstChar: boolean = false;  // show only first letter of severity
```

**Severity model** (from `AlertSeverityDetails`):
```typescript
enum AlertSeverity { Low = 'low', Medium = 'medium', High = 'high', Critical = 'critical' }

interface AlertSeverityDetails {
  displayName: string;
  color: string;
  background: string;
  value?: string;
}
```

---

### `<smart-dropdown>` — Filterable multi/single select
**Path**: `src/app/app/smart-alert/common-custom-filters/smart-dropdown/`
**Selector**: `smart-dropdown`
**Standalone**: Yes (uses MatFormField + MatSelect internally)

```typescript
@Input() options: { value: any; viewValue: string }[] = [];
@Input() selectedOptions: any = [];
@Input() multiple: boolean = false;
@Input() label: string = '';
@Input() width: number = 150;           // px
@Input() selectWidth: number = 70;      // px

@Output() selectionChange: EventEmitter<any>;
```

> Has built-in "select all" logic: when `multiple=true`, include `{ value: 'none', viewValue: 'All' }`
> as the first option and the component handles the select-all/deselect-all logic automatically.

---

### `<template-dropdown>` — Simple component/template selector
**Path**: `src/app/app/standalone-components/reusable-components/template-dropdown/`
**Selector**: `template-dropdown`
**Standalone**: Yes

```typescript
@Input() componentList: any[] = [];          // array of component objects
@Output() selectedComp: EventEmitter<any>;   // emits the selected component
```

---

### `<subscriber-list>` — Displays a list of alert subscribers
**Path**: `src/app/app/standalone-components/reusable-components/subscriber-list/`
**Selector**: `subscriber-list`
**Standalone**: Yes

```typescript
@Input() subscriberList: Subscriber[] = [];
// Subscriber interface: { name?: string; userId?: string }
// Renders avatars with colour cycling: ['#ff9900', '#2b2b2b', '#228B22']
```

---

### `<segment-toggle-switch>` — Active/Inactive tab switch
**Path**: `src/app/app/smart-alert/common-custom-filters/segment-toggle-switch/`
**Selector**: `segment-toggle-switch`
**Standalone**: No (part of SmartAlertsModule)

```typescript
@Input() selectedToggle: string = 'active';   // 'active' | 'inactive'
@Output() onToggle: EventEmitter<string>;     // emits 'active' | 'inactive'
```

---

### `<alert-list-tab>` — Full alerts tab with system/recipe tabs
**Path**: `src/app/app/standalone-components/alert-list-tab/`
**Selector**: `alert-list-tab`
**Standalone**: Yes (imports SmartAlertsModule, MatTabsModule, MatIconModule)

---

## 5. Angular Material Theme

Defined in `src/theme.scss`. Key palette values:

```scss
// Primary: all black shades (custom)
$primary: mat.define-palette($mat-black);   // #000000

// Accent: brand dark teal
$accent: mat.define-palette((500: #072B31, contrast: (500: white)), 500, 500, 500);

// Warn: red
$warn: mat.define-palette(mat.$red-palette, 600);

// Slide toggle: custom green palette
$toggle-palette: (100: #6fdc63, 500: #0f9f05, 700: #0b7304)

// Alternative blue theme (used on elements with class="alternative")
$alt-accent: mat.define-palette(mat.$blue-palette, 600, A100, A400);
```

### ⚠️ Legacy Material imports (migration required)
The codebase currently uses `MatLegacy*` imports in many places. For **new code**, use the non-legacy APIs:

| Legacy (don't add) | Non-legacy (use this) |
|---|---|
| `MatLegacyButtonModule as MatButtonModule` | `MatButtonModule` |
| `MatLegacyDialogModule as MatDialogModule` | `MatDialogModule` |
| `MatLegacyTooltipModule as MatTooltipModule` | `MatTooltipModule` |
| `MatLegacyMenuModule as MatMenuModule` | `MatMenuModule` |
| `MatLegacyInputModule` | `MatInputModule` |
| `MatLegacyFormFieldModule` | `MatFormFieldModule` |

Do not add new `MatLegacy*` imports to any module. Existing ones stay until migrated.

---

## 6. PrimeNG Theme & Style Override Patterns

PrimeNG is configured with `lara-light-blue` theme. The **accent colour is `#f90` (orange)**, NOT the
dark teal. This is set globally in `styles.css` and overrides the PrimeNG theme variables.

### styles order in angular.json (order matters — do not change)
```
"node_modules/primeicons/primeicons.css"   ← PrimeNG icons
"src/styles.css"                           ← SJ global tokens + PrimeNG overrides
"src/theme.scss"                           ← Angular Material palette
"node_modules/primeng/resources/themes/lara-light-blue/theme.css"
"node_modules/primeng/resources/primeng.min.css"
```

### Global PrimeNG overrides already in styles.css (DO NOT re-add these)
```css
/* Dropdown focus/hover → orange accent */
.p-dropdown:not(.p-disabled):hover        { border-color: #f90 !important; }
.p-dropdown:not(.p-disabled).p-focus      { border-color: #f90 !important; box-shadow: none !important; }
.p-dropdown-panel .p-dropdown-items
  .p-dropdown-item.p-highlight            { color: #f90 !important; background: rgba(255,153,0,0.1) !important; }

/* Checkbox → primary color */
.p-checkbox .p-checkbox-box.p-highlight   { border-color: var(--n-primary-color) !important; background: var(--n-primary-color) !important; }
.p-checkbox .p-checkbox-box               { width: 14px !important; height: 14px !important; border-radius: 2px !important; }

/* Button outlined → orange */
.p-button.p-button-outlined               { color: #f90 !important; background: #fff !important; }
.p-button-label                           { font-weight: 400 !important; }

/* Tooltip text size */
.p-tooltip-text                           { font-size: 13px !important; }

/* ConfirmPopup */
.p-confirm-popup-accept                   { background-color: #f90 !important; border-color: #f90 !important; }
.p-confirm-popup-icon                     { color: var(--n-sys-red) !important; }
```

### How to override PrimeNG styles in a component
PrimeNG renders many elements outside the component's shadow DOM (overlays, panels, tooltips).
Because of this, component-scoped CSS **will not reach** those elements.

**Correct pattern** (as used in png-table, device-list, bacnet-mapping):
1. Set `encapsulation: ViewEncapsulation.None` on the component
2. Add `!important` to all PrimeNG class overrides
3. Scope with a wrapper class to avoid polluting other components

```css
/* ✅ CORRECT — ViewEncapsulation.None + wrapper class + !important */
.my-feature-container .p-datatable-thead th {
  background: white !important;
  font-size: 12px !important;
}
.my-feature-container .p-dropdown .p-dropdown-label {
  padding: 0.35rem !important;
  font-size: 14px !important;
}

/* ❌ WRONG — will not work, encapsulation blocks it */
.p-datatable-thead th { background: white; }
```

### PrimeNG table CSS classes to know
```css
.p-datatable-thead > tr > th      /* column headers */
.p-datatable-tbody > tr           /* data rows — add hover/selected here */
.p-datatable-tbody > tr > td      /* cells */
.p-datatable .p-datatable-header  /* caption/header bar */
.p-column-filter-overlay          /* filter dropdown overlay */
.p-multiselect-panel              /* multiselect overlay panel */
```

### Real override example from png-table.component.css
```css
.prime-custom--table .p-datatable .p-datatable-tbody > tr {
  color: #7a7a7a !important;
  height: 42px !important;
}
.prime-custom--table .p-datatable .p-datatable-tbody > tr > td {
  white-space: nowrap !important;
}
.p-datatable-thead th {
  background: white !important;
}
.p-datatable .p-datatable-header {
  background: white !important;
  display: flex;
  justify-content: space-between;
  border-width: 0 0 1px 0;
}
```

### PrimeNG module imports
```typescript
import { TableModule }        from 'primeng/table';
import { DropdownModule }     from 'primeng/dropdown';
import { SkeletonModule }     from 'primeng/skeleton';
import { TooltipModule }      from 'primeng/tooltip';
import { ChipModule }         from 'primeng/chip';
import { ButtonModule }       from 'primeng/button';
import { InputTextModule }    from 'primeng/inputtext';
import { DialogModule }       from 'primeng/dialog';
import { MultiSelectModule }  from 'primeng/multiselect';
import { InputSwitchModule }  from 'primeng/inputswitch';
import { ConfirmPopupModule } from 'primeng/confirmpopup';
import { MenuModule }         from 'primeng/menu';
```

---

## 6b. `app-button` — SJ Internal Button Component

**This is the primary button in DeJoule. Use it instead of `mat-button` or `p-button` for all actions.**

**Selector**: `button[app-button]` or `a[app-button]`
**Path**: `src/app/components/button/button.component.ts`
**Part of**: `ComponentsModule`

```html
<!-- Primary action -->
<button app-button type="primary" [label]="'Save'"></button>

<!-- Secondary (outlined) -->
<button app-button type="secondary" [label]="'Cancel'"></button>

<!-- Text only -->
<button app-button type="text" [label]="'Close'" mat-dialog-close></button>

<!-- With leading icon (Material Symbols name) -->
<button app-button type="secondary" [leadingIcon]="'refresh'" [label]="'Refresh'"></button>

<!-- With trailing icon + loading state -->
<button app-button type="secondary" [label]="'Sync All'" [trailingIcon]="'sync'" [loading]="isSyncLoading"></button>

<!-- Icon only (no label) -->
<button app-button type="secondary" [leadingIcon]="'download'"></button>

<!-- Disabled -->
<button app-button type="primary" [label]="'Submit'" [disabled]="!form.valid"></button>
```

**@Input() API**:
```typescript
@Input() type: 'primary' | 'secondary' | 'text' = 'primary';
@Input() label: string = '';
@Input() leadingIcon: string = '';   // Material Symbols icon name
@Input() trailingIcon: string = '';  // Material Symbols icon name
@Input() loading: boolean = false;   // shows spinner, disables clicks
@Input() disabled: boolean = false;
@Input() selected: boolean = false;  // persistent selected state (secondary only)
@Input() fontSize: string = '14px';
```

**Visual states**:
- `primary` → `background: var(--n-primary-color)` (#072B31), white text; hover → `var(--n-accent-color)` (#28939D)
- `secondary` → white bg, `border: 1px solid var(--n-primary-color)`; hover → accent bg + white text
- `text` → transparent, no border; hover → `rgba(7,43,49,0.2)` bg
- `secondary` + `[selected]="true"` → same as primary (dark bg, white text)

---

## 7. NgRx Patterns

The app uses NgRx Store (global) + NgRx Component-Store (local/feature).

### Global store slices
Located in `src/app/actions/` and `src/app/reducers/`:
- `site` — current site selection
- `user` — authenticated user info
- `token` — JWT token
- `page` — current page/route state
- `component` — component type selections
- `recipe` — recipe dict (abstract + single)
- `process` — process state

### Component-Store usage
For feature-level state (e.g. `RecipeConfigStore`, `componentsStateStore`):
```typescript
import { ComponentStore } from '@ngrx/component-store';

// Located in: feature-folder/component-store/<name>.store.ts
```

### Standard import pattern
```typescript
import { Store, select } from '@ngrx/store';
import { EffectsModule } from '@ngrx/effects';
import { StoreModule } from '@ngrx/store';
```

---

## 8. File Structure Conventions

```
src/app/
├── app/                          # Feature modules
│   ├── smart-alert/              # Alerts feature
│   │   ├── common-custom-filters/    # Shared filter components (smart-dropdown, segment-toggle)
│   │   ├── reusable-components/      # Alert-specific reusable components
│   │   ├── component-store/          # NgRx Component-Store for this feature
│   │   └── models/                   # TypeScript interfaces/enums
│   ├── standalone-components/        # Cross-feature standalone components
│   │   ├── reusable-components/      # png-table, severity-chips, subscriber-list, etc.
│   │   └── alert-list-tab/           # Top-level tab component
│   └── rapid-plant-builder/          # Plant SVG builder feature
├── components/                   # ComponentsModule — legacy shared components
├── pipes/                        # PipesModule — shared pipes
├── guards/                       # Route guards
├── sharedServices/               # HTTP interceptors, error handling
├── utilities/                    # configurator.util, common.util (exportToCsv etc.)
├── actions/                      # NgRx action classes
├── reducers/                     # NgRx reducers
└── effects/                      # NgRx effects
```

### Standalone component pattern (preferred for new components)
```typescript
@Component({
  selector: 'my-component',
  standalone: true,
  imports: [CommonModule, /* specific modules only */],
  templateUrl: './my-component.component.html',
  styleUrls: ['./my-component.component.css'],
  encapsulation: ViewEncapsulation.None,
})
export class MyComponent { }
```

---

## 9. Anti-Patterns — Never Do These

- ❌ **Do NOT hardcode hex colours**. Use `var(--n-*)` CSS custom properties.
- ❌ **Do NOT install new UI libraries** for things already in the stack (date pickers, tables, dropdowns).
- ❌ **Do NOT build custom UI when a PrimeNG or SmartJoules internal component exists. PrimeNG is the default for new UI components.**
- ❌ **Do NOT add new `MatLegacy*` imports**. Use non-legacy Material APIs.
- ❌ **Do NOT introduce Material Symbols, PrimeIcons, or custom SVGs for new icons when Boxicons covers the need.**
- ❌ **Do NOT use `mat-table` or any Angular Material table for data grids** — this is absolute. Always `p-table`.
- ❌ **Do NOT put filters outside the table** (separate filter bar above the table). Filters belong inside `<ng-template pTemplate="header">` as a second `<tr>` row using `p-columnFilter`. See §3 Tier 2.
- ❌ **Do NOT use a bare `<h1>` or custom heading HTML** for page titles. Always use the standard heading structure from §16 with `app-button` for actions.
- ❌ **Do NOT use `template-driven` forms** (`ngModel`). Use `ReactiveFormsModule`.
- ❌ **Do NOT use MatTooltip** for new code. Use PrimeNG `pTooltip`.
- ❌ **Do NOT use `any` for severity values**. Use the `AlertSeverity` enum.
- ❌ **Do NOT recreate subscriber/severity/table UI**. The internal components exist and should be used.
- ❌ **Do NOT inline status colours**. Use `getConfigStatusColor()` pattern or `var(--n-sys-*)` tokens.
- ❌ **Do NOT style PrimeNG components without `ViewEncapsulation.None`**. Overlays, panels, dropdowns render outside component scope — styles need `encapsulation: ViewEncapsulation.None` + `!important`.
- ❌ **Do NOT use `mat-button` or `p-button` for primary actions**. Use `<button app-button>` — the SJ internal `AppButtonComponent` from `ComponentsModule`.
- ❌ **Do NOT expect `--n-accent-color` to be the PrimeNG accent**. PrimeNG globally uses `#f90` orange as its interactive accent. Do not re-override this.
- ❌ **Do NOT scope PrimeNG overlay overrides to component**. Dropdown panels render at `body` level — use global `styles.css` or `ViewEncapsulation.None` with a wrapper class.
- ❌ **Do NOT use `MatLegacySnackBar` in new code**. `HandleErrorService` uses it (legacy). New snackbar usage should import non-legacy `MatSnackBar` from `@angular/material/snack-bar`.
- ❌ **Do NOT create custom loading spinners**. Use PrimeNG `SkeletonModule` for table/card loading, or the internal `<loading-dots>` component for inline loading. See §18 for the standard skeleton pattern.
- ❌ **Do NOT display raw API error messages to users**. Route HTTP errors through `HandleErrorService` which formats and reports to Sentry. See §18.
- ❌ **Do NOT hardcode chart colours**. Use the SJ Highcharts palette from §19.
- ❌ **Do NOT build UI without keyboard operability**. Every interactive element must work with Tab/Enter/Escape. See §17.
- ❌ **Do NOT use colour alone to convey status**. Pair `--n-sys-*` colours with text labels or icons. See §17.
- ❌ **Do NOT omit `pTemplate="emptymessage"` on any `p-table`**. Every table must have a meaningful empty state. See §18.
- ❌ **Do NOT skip `pTooltip` on truncated text**. If `text-ellipsis` is applied, always add a tooltip showing the full value.

---

## 10. Quick Reference — "How do I add X?"

### A new lazy-loaded feature module
1. Create folder `src/app/app/<feature>/`
2. Create `<feature>.module.ts` and `<feature>-routing.module.ts`
3. Register in `app-routing.module.ts` with `loadChildren`

### A standalone reusable component
1. Create under `src/app/app/standalone-components/reusable-components/<name>/`
2. Mark `standalone: true` in `@Component`
3. Import only what it needs (no shared module bloat)
4. Export from a barrel or import directly where used

### Status colour for a device/component
```typescript
// Use these always:
online / synced   → 'var(--n-sys-green)'   // #228B22
warning / partial → 'var(--n-sys-orange)'  // #FF9900
offline / failed  → 'var(--n-sys-red)'     // #FF0F00
unknown           → '#7A7A7A'
```

### CSV export
```typescript
import { exportToCsv } from 'app/utilities/common.util';
exportToCsv(`filename-${siteId}.csv`, dataArray, headerArray);
```

### Snackbar / toast message
```typescript
import { RapidPlantBuilderService } from 'app/app/rapid-plant-builder/rapid-plant-builder.service';
this.rapidPlantBuilderService.displaySnackbarMessage('Your message here');
```

---

## 11. Domain Vocabulary

These terms have specific meaning in the SmartJoules domain:

| Term | Meaning |
|---|---|
| Site | A physical building/facility being monitored |
| Component | A physical HVAC equipment item (chiller, pump, AHU, cooling tower) |
| Process | A grouping of components (e.g. a chiller plant) |
| Recipe | An automation rule (condition → action) |
| Alert | A triggered notification from a recipe or system |
| JouleBox | The edge IoT controller hardware |
| JouleLeaf / JouleStat | Smaller IoT sensor nodes |
| Configurator | The UI section for mapping components and parameters |
| CPA | Chiller Plant Automation — the core control algorithm |
| DeJoule | Internal product name for the full platform |

---

## 12b. Page Headings — ENFORCED PATTERN (must always follow)

> ⛔ **ABSOLUTE**: Every new page in JouleTRACK MUST use the standard page heading structure below.
> Never use a bare `<h1>` or custom heading HTML. Cody must enforce this on every page scaffold.

**Standard page heading structure** (use this exact HTML every time):

```html
<!-- ✅ CORRECT — standard SJ page heading -->
<div class="flex-space-btw" style="margin-bottom: 20px; align-items: flex-start; flex-wrap: wrap; gap: 12px;">
  <div class="flex-v gap-4">
    <h1 style="font-size: 20px; font-weight: 500; color: var(--n-primary-color); margin: 0;">
      Page Title Here
    </h1>
    <p style="font-size: 13px; color: var(--n-primary-title-color); margin: 0; font-weight: 400;">
      Short descriptive subtitle for context
    </p>
  </div>

  <!-- Right side: actions using app-button only -->
  <div class="flex-h align-center gap-8">
    <button app-button type="secondary" [leadingIcon]="'refresh'" [label]="'Refresh'"
            (click)="onRefresh()">
    </button>
    <button app-button type="primary" [leadingIcon]="'download'" [label]="'Export CSV'"
            (click)="onExport()">
    </button>
  </div>
</div>
```

**Rules for headings:**
- `h1` font-size: always `20px`, font-weight `500`, colour `var(--n-primary-color)`
- Subtitle: always `13px`, `font-weight: 400`, colour `var(--n-primary-title-color)`
- Right-side actions: always `<button app-button>` — never `mat-button`, `p-button`, or `<button>` alone
- Wrapper: always `flex-space-btw` utility class (from `styles.css`)
- Never put the page heading inside the `p-table` caption template — it belongs above the table

**❌ Anti-patterns for headings:**
```html
<!-- ❌ WRONG — bare h1, no subtitle, no structure -->
<h1>Supervisory Control</h1>

<!-- ❌ WRONG — mat-button in heading actions -->
<button mat-stroked-button>Refresh</button>

<!-- ❌ WRONG — heading inside p-table caption -->
<ng-template pTemplate="caption">
  <h2>My Table</h2>
</ng-template>
```

Import `PipesModule` from `app/pipes/pipes.module` to use any of these in a module/component.

| Pipe name (template) | Class | Usage |
|---|---|---|
| `momentPipe` | `CustomPipeMoment` | Unix timestamp → `"DD MMM YYYY hh:mm A"` via moment.js |
| `roundOff` | `CustomPipeRoundOff` | Round numbers for display |
| `displayName` | `CustomPipeDisplayName` | Human-readable display name from key |
| `safeHtml` | `SafeHtml` | Bypass DomSanitizer for trusted HTML |
| `unitPreference` | `UnitPreference` | Apply user unit preference (°C/°F etc.) |
| `applyBrackets` | `ApplyBrackets` | Wrap value in brackets |
| `dejoulePriority` | `DejoulePriorityPipe` | Recipe priority label |
| `formatName` | `FormatName` | camelCase key → "Camel Case" label (e.g. `actuatorControl` → `Actuator Control`) |
| `timeElapsed` | `TimeElapsedPipe` | Human-readable elapsed time |
| `globalParamFormatter` | `GlobalParamFormatterPipe` | Format parameter values by type |
| `firstLetterCap` | `FirstLetterCapPipe` | Capitalise first letter |
| `stringToArray` | `StringToArrayPipe` | Split string to array |
| `paramDetails` | `ParamDetailsPipe` | Format parameter detail object |
| `filterByField` | `FilterByFieldPipe` | Filter array by field value |
| `highlight` | `HighlightPipe` | Highlight search term in text |
| `search` | `SearchPipe` | Search/filter array by query |
| `truncate` | `TruncatePipe` | Truncate long strings |
| `cdn` | `CdnPipe` | Prepend CDN base URL to asset path |

**Usage in component:**
```typescript
// In module:
import { PipesModule } from 'app/pipes/pipes.module';

// In standalone component:
imports: [PipesModule]

// In template:
{{ timestamp | momentPipe }}
{{ deviceKey | formatName }}
{{ value | roundOff }}
{{ htmlString | safeHtml }}
```

---

## 13. Navigation System — How to Add a New Page to Nav

Navigation is driven by `NavigationMenuList` in `src/app/constants/navigationMenuList.ts`.
Each entry is a `MenuItem` object. Adding a new top-level page requires:

**Step 1 — Add to NavigationMenuList:**
```typescript
{
  name: 'Supervisory Control',          // display name in sidebar
  img: 'assets/icons/ico-form.svg',    // SVG icon (use existing icons in assets/icons/)
  excludeSites: [],                     // site IDs to hide this from
  specificSites: [],                    // if set, only show for these sites
  specificUsers: [],                    // if set, only show for these user emails
  route: 'supervisory-control',         // Angular router path
  policy: 'AC Plant_View',             // RBAC policy key (see Policy interface)
  visibility: true,
  child: [],                            // sub-menu items (empty = no dropdown)
}
```

**Step 2 — Register route in `app-routing.module.ts`:**
```typescript
{
  path: 'supervisory-control',
  loadChildren: () =>
    import('./app/supervisory-control/supervisory-control.module')
      .then(m => m.SupervisoryControlModule),
  canActivate: [AuthGuard],
}
```

**Policy keys** (from `src/app/models/policy.ts`) — use these for `policy` field:
- `'AC Plant_View'` — HVAC/plant pages
- `'Configuration_View'` — config pages
- `'Device_View'` — device pages
- `'User_View'` — user management
- `'Consumption_View'` — energy pages
- `'Joule Recipes_View'` — recipe pages
- `'SMART_ALERT_View'` — alerts
- `undefined` — no policy gate (visible to all authenticated users)

**`specificUsers`** — restrict a nav item to specific email addresses (used for internal tools like Driver Management).

---

## 14. ComponentsModule — What It Contains

`ComponentsModule` from `src/app/components/components.module.ts` exports:

| Component | Selector | Use for |
|---|---|---|
| `AppButtonComponent` | `button[app-button]`, `a[app-button]` | **All** primary/secondary/text actions |

Import `ComponentsModule` in any feature module that uses `<button app-button>`.

```typescript
import { ComponentsModule } from 'app/components/components.module';

@NgModule({
  imports: [ComponentsModule, ...]
})
```

For **standalone components**, import `AppButtonComponent` directly:
```typescript
import { AppButtonComponent } from 'app/components/button/button.component';

@Component({
  standalone: true,
  imports: [AppButtonComponent, ...]
})
```

---

## 15. NgRx Global Store — Complete Slice List

From `src/app/reducers/index.ts`, the full global store shape:

```typescript
{
  navigation:    NavigationState,   // sidebar nav items + active state
  page:          PageState,         // current page identifier
  user:          UserState,         // authenticated user info + JWT claims
  policy:        PolicyState,       // RBAC policy map (Policy interface)
  processes:     ProcessState,      // process list
  processesDict: ProcessDictState,  // process keyed by id
  devices:       DeviceState,       // device list
  // + site, token, component, recipe slices (see reducers/)
}
```

**Accessing policy for permission checks:**
```typescript
this.store$.pipe(select('policy')).subscribe((policy: Policy) => {
  this.canEdit = !!policy?.Configuration_Edit;
  this.canView = !!policy?.['AC Plant_View'];
});
```

**Accessing current site:**
```typescript
this.store$.pipe(select('site')).subscribe((site: any) => {
  this.siteId = site?.siteId;
});
```

---

## 16. Design Quality Standards (from Impeccable by Paul Bakaus)

This section integrates the Impeccable design intelligence framework into the SJ skill.
Apply these rules on every UI component, page, and widget generated for DeJoule/JouleTRACK.

Source: https://github.com/pbakaus/impeccable (Apache 2.0)

---

### 16a. Typography Rules

**Work Sans is the SJ brand font — already set globally. It is an intentional choice (not an "invisible default" like Inter/Roboto). But apply these rules within it:**

**Impeccable's 5-dimension type assessment applied to SJ:**
1. **Font choice**: Work Sans — intentional, distinctive, good. Do NOT introduce a second body font.
2. **Hierarchy**: Heading weight 600 for key headings (h1 can stay 500 per §12b, but section headings within a page should use 600 for contrast). Body weight 400. Minimum weight contrast: 2 steps.
3. **Sizing and scale**: Fixed `rem` scales (not fluid `clamp`) — data-dense product UI, not a marketing page.
4. **Readability**: Line-height tuned per context (see below). Body at 13-14px, never below 11px.
5. **Consistency**: Same element = same treatment everywhere. No one-off `font-size` overrides.

**Type scale with hierarchy** — Use fewer sizes with more contrast. Aim for at least a 1.25× ratio between steps.

Recommended scale for DeJoule:
```css
--text-xs:   11px;   /* labels, badges, timestamps */
--text-sm:   12px;   /* table cell content, secondary info */
--text-base: 13px;   /* primary table content, body */
--text-md:   14px;   /* filter labels, card subtitles */
--text-lg:   16px;   /* section headings */
--text-xl:   20px;   /* page titles */
--text-2xl:  28px;   /* summary metric values */
```

**Line height** — scales inversely with line length. For DeJoule's dense tables: `line-height: 1.4`. For readable prose sections: `line-height: 1.6`.

**Body text line length** — cap at 65–75ch. Never let paragraphs run full-width.

**NEVER do these:**
- ❌ All-caps body text (labels only, max 3 words)
- ❌ Monospace as "technical" shorthand — use Work Sans, only use mono for actual code/tags (BMS tags, component IDs)
- ❌ Flat hierarchy — page title and table headers at same or near-same size
- ❌ Letter-spacing on body text (>0.05em on body = harder to read)
- ❌ Tight line height below 1.3x on multi-line text
- ❌ Skipped heading levels (`<h1>` then `<h3>` with no `<h2>`) — breaks a11y and visual hierarchy
- ❌ Justified text (`text-align: justify`) — creates whitespace rivers on screen without hyphenation
- ❌ Text below 11px (`--text-xs`) — unreadable for facility managers on standard monitors
- ❌ Wide letter-spacing (>0.1em) on body copy — slows reading by breaking character groupings

---

### 16b. Colour & Contrast Rules

**SJ has a defined palette. Apply Impeccable's colour intelligence within it:**

**Use tinted neutrals — already done in SJ** (`--n-screen-bg-color: #f6f6f6` is slightly warm, not pure white). Maintain this — never introduce pure `#fff` backgrounds except on cards/panels.

**60-30-10 weight rule for SJ screens:**
- 60% → surface neutrals (`--n-screen-bg-color`, `--n-white`, `--n-highlight-color`)
- 30% → text and borders (`--n-black`, `--n-primary-title-color`, `--n-border-color`)
- 10% → accent use only (`--n-primary-color`, `--n-accent-color`, `--n-sys-*` status colours)

**Status colours are ACCENT — use sparingly:**
- `--n-sys-green` / `--n-sys-orange` / `--n-sys-red` are for status chips and indicators ONLY
- Never use them as backgrounds for large areas
- Never use them as text colour on a coloured background — always use a darker shade of that family

**OKLCH for new colour generation** — when deriving shades (e.g. chart series, hover states), compute in OKLCH for perceptually uniform steps. Equal lightness steps in OKLCH look equal to the eye, unlike HSL.
```css
/* Example: deriving a lighter tint of primary for hover */
/* --n-primary-color #072B31 ≈ oklch(19% 0.03 195) */
/* Lighter tint: increase L, keep C and H */
/* oklch(30% 0.03 195) → approx #0E4A54 */
```

**Contrast minimums (WCAG 2.1 AA):**
- Normal text (≤18px): **4.5:1** minimum
- Large text (>18px or >14px bold): **3:1** minimum
- UI components and graphical objects: **3:1** minimum

**NEVER do these:**
- ❌ Gray text on coloured backgrounds (e.g. `color: #888` on a green/orange chip background) — use `#1b5e20` on green-bg, `#bf360c` on orange-bg
- ❌ Pure black `#000` or pure white `#fff` for full-page backgrounds
- ❌ Purple/blue gradient → this is the AI colour palette fingerprint
- ❌ Gradient text (`background-clip: text`) — solid colours only
- ❌ Dark backgrounds with glowing box-shadows (`box-shadow: 0 0 Xpx color`)
- ❌ Cyan-on-dark accent schemes

---

### 16c. Layout & Spacing Rules

**SJ uses an implicit spacing system — make it explicit. Always use this 4pt scale:**

```css
/* Use these values only — nothing in between */
4px   /* micro: icon-to-label gap */
8px   /* tight: related elements within a group */
12px  /* close: internal card padding top/bottom */
16px  /* default: standard padding, gap between sibling items */
24px  /* medium: between distinct sections within a card */
32px  /* large: between cards in a grid */
48px  /* xlarge: major section separations */
64px  /* page-level breathing room */
```

**Use `gap` not margins** for sibling spacing — eliminates margin collapse.

**Vary spacing for hierarchy** — a row of summary cards needs 12px internal padding but 32px gap between cards and the table below. Don't apply the same padding everywhere.

**Self-adjusting grid for summary cards:**
```css
grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
```

**The 2-second rule** — the eye must land on the primary action or key metric within 2 seconds. For data-dense SJ pages, this means summary cards or the key metric must be visually dominant above the fold. If everything looks equally important, nothing is.

**Density matching** — data-dense pages (device lists, parameter tables) use tight spacing (8-12px gaps). Prose-heavy pages (alerts detail, recipe descriptions) use generous spacing (16-24px gaps). Match density to content type.

**NEVER do these:**
- ❌ Wrap every element in a card — not every piece of content needs a bordered container
- ❌ Cards nested inside cards (cardocalypse) — use spacing, typography, dividers instead
- ❌ Identical card grids — icon + heading + text repeated endlessly
- ❌ Everything centered — left-aligned with asymmetric layouts feels more designed
- ❌ Same padding/gap everywhere — monotonous spacing kills rhythm
- ❌ Border-left or border-right >1px as a coloured accent stripe on cards/alerts — this is the #1 AI UI tell. DeJoule's existing row highlighting uses left-border on table rows ONLY, which is acceptable because it's a functional diff indicator, not decorative. Do not extend this pattern to cards or alert boxes.
- ❌ Cramped padding on buttons/chips (< 6px vertical) — touch targets need at least 8px vertical padding
- ❌ Icon-tile stacks (rounded gradient icon above heading above text, repeated in a grid) — the #2 AI UI tell

---

### 16d. Visual Detail Rules (Anti-AI-Slop)

The **AI Slop Test**: if someone saw this and immediately knew "AI made this" — that's the failure. A distinctive DeJoule interface should look designed for industrial energy management, not generated by a default template.

**BANNED CSS patterns (match-and-refuse — if you see yourself writing these, stop and rewrite):**

```css
/* BAN 1: Side-stripe accent borders on cards/alerts/callouts */
border-left: 3px solid var(--n-sys-red);    /* ❌ on cards/alerts */
border-left: 4px solid var(--n-primary-color); /* ❌ on cards */
/* Exception: table row status indicator is OK (functional, not decorative) */

/* BAN 2: Gradient text */
background: linear-gradient(...);
-webkit-background-clip: text;             /* ❌ never */

/* BAN 3: Glassmorphism */
backdrop-filter: blur(Xpx);               /* ❌ decorative use */
background: rgba(255,255,255,0.1);        /* ❌ frosted glass cards */

/* BAN 4: Glow shadows */
box-shadow: 0 0 20px rgba(color, 0.5);   /* ❌ neon glow effect */

/* BAN 5: Generic rounded-rect + drop-shadow card */
border-radius: 8px;
box-shadow: 0 4px 6px rgba(0,0,0,0.1);   /* ❌ if that's the ONLY design decision */
```

**DO instead:**
- Use flat surfaces with subtle `0.5px` borders at `var(--n-border-color)`
- Differentiate cards with background tints (`--n-highlight-color`) not shadows
- Use spacing and typography for hierarchy, not border decoration
- For status/alert states: use background-color tints + coloured text, not border stripes

---

### 16e. Motion Rules

DeJoule is an operational tool — motion must communicate state, not decorate.

**Acceptable motion:**
```css
/* Expand/collapse transitions — use grid-template-rows, not height */
.detail-panel { display: grid; grid-template-rows: 0fr; transition: grid-template-rows 0.18s ease-out; }
.detail-panel.open { grid-template-rows: 1fr; }

/* State change feedback */
transition: background 0.1s ease, color 0.1s ease;

/* Fade in for new content */
@keyframes fadeSlideIn {
  from { opacity: 0; transform: translateY(-4px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* Easing — always exponential deceleration */
transition-timing-function: cubic-bezier(0.16, 1, 0.3, 1); /* ease-out-quint */
```

**NEVER:**
- ❌ `animation-timing-function: bounce` or `elastic` — feels dated and tacky
- ❌ Animate `width`, `height`, `padding`, `margin` — use `transform` and `opacity`
- ❌ Page-load animations on data tables — operators need data immediately
- ❌ `will-change: all` — be specific (`will-change: transform`)
- ❌ Animations without `@media (prefers-reduced-motion: no-preference)` guard

---

### 16f. Interaction Rules

**Progressive disclosure** — DeJoule tables handle large data. Design for progressive reveal:
- Show essential columns by default, allow column toggling
- Row expand shows detail, not a separate dialog
- Filters appear inline, not in a modal overlay
- Error states appear inline in the row, not as popups

**Button hierarchy** — every screen has ONE primary action. The rest are secondary or text:
```html
<!-- Primary: one per screen -->
<button app-button type="primary" [label]="'Export CSV'"></button>

<!-- Secondary: supporting actions -->
<button app-button type="secondary" [label]="'Refresh'"></button>

<!-- Text: destructive or low-importance -->
<button app-button type="text" [label]="'Reset'"></button>
```

**Empty states must teach** — never just "No data":
```
❌ "No parameters found."
✅ "No parameters match the current filters. Try removing the equipment type filter."
```

**Error messages must be actionable:**
```
❌ "Error 500"
✅ "Failed to load supervisory data. Check your connection and retry."
```

**Focus states — EVERY interactive element must have a visible focus indicator:**
```css
/* Standard SJ focus ring — add to global styles.css */
:focus-visible {
  outline: 2px solid var(--n-accent-color);
  outline-offset: 2px;
}
/* For dark backgrounds (nav sidebar): */
.dark-bg :focus-visible {
  outline-color: var(--n-white);
}
```
PrimeNG components have built-in focus styles — do not remove them. For custom interactive elements (`app-button`, `segment-toggle-switch`, custom clickable rows), ensure `:focus-visible` is styled.

**NEVER:**
- ❌ Every button styled as primary (hierarchy collapse)
- ❌ Modals for confirmations that could be inline — use PrimeNG ConfirmPopup (already used in png-table)
- ❌ Redundant information — don't restate the page title in the first paragraph
- ❌ "Not available on mobile" — adapt the interface, don't amputate features
- ❌ Hiding critical columns on tablet — stack or abbreviate instead
- ❌ Removing focus outlines (`outline: none`) without providing an alternative — breaks keyboard navigation
- ❌ Interactive elements without hover AND focus states — both are required

---

### 16g. UX Writing Rules (from Impeccable)

Apply to all labels, error messages, empty states, tooltips, and button text in DeJoule.

**Button labels — verb + noun, action-oriented:**
```
❌ "Submit"       ✅ "Export CSV"
❌ "OK"           ✅ "Refresh data"
❌ "Cancel"       ✅ "Discard changes"
❌ "Yes"          ✅ "Relinquish control"
```

**Error message formula: What happened + Why + What to do:**
```
❌ "Error loading data"
✅ "Could not load supervisory data — the API may be unreachable. Retrying in 10s."

❌ "Invalid state"
✅ "This parameter is in conflict: DeJoule last wrote 7.5°C but BMS is reporting 9.0°C."
```

**Tooltip formula — describe the non-obvious, skip the obvious:**
```
❌ tooltip on Refresh button: "Click to refresh"   (obvious)
✅ tooltip on Refresh button: "Fetch latest write states from the BMS integration layer"

❌ tooltip on stale dot: "Stale"
✅ tooltip on stale dot: "No update received in >30s — check IoT gateway connection"
```

**Empty state formula — what's missing + why + what to do:**
```
❌ "No parameters found."
✅ "No controlled parameters match the selected filters.
    Try clearing the Equipment Type or Write Source filter."
```

**Status label vocabulary for DeJoule:**
```
Write Source:  DeJoule | Local BMS | Relinquished    (not: "System" / "Manual" / "Released")
Status:        Active | Override | Error | Relinquished
Equipment:     Chiller | Cooling Tower | Pump | AHU   (title case, spelt out, not abbreviations in UI)
```

---

### 16h. The AI Slop Audit Checklist

Before delivering any UI component or page for DeJoule, run this mental checklist.
This maps all 25 Impeccable anti-pattern detections + SJ-specific checks.

**Typography (Impeccable: overused-font, single-font, flat-type-hierarchy, all-caps-body, tight-leading, skipped-heading, justified-text, tiny-text, wide-tracking, line-length)**
- [ ] Type scale has at least 1.25× ratio between adjacent steps
- [ ] No all-caps body text (labels only, max 3 words)
- [ ] Mono used only for BMS tags, component IDs, values — not as "technical" branding
- [ ] Line length capped at ~70ch for readable prose sections
- [ ] No skipped heading levels (h1 → h3 without h2)
- [ ] No justified text
- [ ] No text below 11px
- [ ] Line height ≥ 1.3x on multi-line text
- [ ] No wide letter-spacing (>0.1em) on body

**Colour (Impeccable: ai-color-palette, gradient-text, dark-glow, gray-on-color, low-contrast, pure-black-white)**
- [ ] No gray text on coloured chip/badge backgrounds
- [ ] No gradient text (`background-clip: text`)
- [ ] No purple/blue gradient (AI colour palette)
- [ ] No glow box-shadows (`box-shadow: 0 0 Xpx`)
- [ ] No pure `#000` or `#fff` for full-page backgrounds
- [ ] Status colours used sparingly (10% rule)
- [ ] All text meets WCAG AA contrast (4.5:1 normal, 3:1 large)

**Layout (Impeccable: side-tab, border-accent-on-rounded, nested-cards, monotonous-spacing, everything-centered, icon-tile-stack, cramped-padding)**
- [ ] No border-left accent stripes on cards/alerts
- [ ] No thick coloured borders on rounded corners (side-tab + border-radius clash)
- [ ] No cards nested in cards
- [ ] Spacing uses the 4pt scale (4/8/12/16/24/32/48/64)
- [ ] Not everything is center-aligned
- [ ] Summary grid uses `auto-fit`, not fixed 4-column
- [ ] No icon-tile-stack grid pattern (rounded-icon → heading → text repeated)
- [ ] No cramped padding on interactive elements (min 8px vertical)
- [ ] Eye lands on primary action/metric within 2 seconds

**Interaction**
- [ ] Only one primary button per view
- [ ] Empty state teaches, not just informs (see §18)
- [ ] Error message includes what to do next
- [ ] Tooltips add value, don't restate the label
- [ ] Every interactive element has visible `:focus-visible` indicator
- [ ] Tables have `pTemplate="emptymessage"` with actionable guidance

**Motion (Impeccable: bounce-easing, layout-transition)**
- [ ] No bounce/elastic easing
- [ ] No `width`/`height`/`padding`/`margin` animations — use `transform` + `opacity`
- [ ] Height animations use `grid-template-rows`
- [ ] `@media (prefers-reduced-motion: no-preference)` guard on keyframe animations

**Accessibility (§17)**
- [ ] All form inputs have visible labels or `aria-label`
- [ ] Colour is not the sole indicator of status
- [ ] Custom components are keyboard-operable (Tab/Enter/Escape)

**The final test**: Would a facility manager at 2am, troubleshooting a chiller override, trust this interface? If it looks like a generic SaaS dashboard, go back. If it looks like a precision operational tool — ship it.

Run `npx impeccable detect` on the built HTML for automated detection of the 25 deterministic anti-patterns.

---

## 17. Accessibility Standards

> JouleTRACK currently has minimal accessibility coverage. This section establishes the baseline
> for all new code. Retrofit existing components as they are touched.

### 17a. Keyboard Navigation

Every interactive element must be operable via keyboard (Tab, Enter, Space, Escape, Arrow keys).

**Built-in keyboard support (already works — do not break):**
- PrimeNG `p-table` sort headers, filters, row expansion
- PrimeNG `p-dropdown`, `p-multiSelect` — arrow keys, type-ahead
- Angular Material dialogs — focus trap, Escape to close
- `app-button` — inherits native `<button>` keyboard behaviour

**Must add keyboard support to:**
- `segment-toggle-switch` — needs `role="tablist"`, arrow keys to switch, Enter/Space to select
- `smart-dropdown` — inherits from MatSelect (works), but verify Tab order in filter rows
- Custom clickable `<div>`/`<span>` elements — convert to `<button>` or add `role="button"` + `tabindex="0"` + keydown handler
- Row-level actions in tables (edit, delete icons) — must be focusable with Tab within the row

```typescript
// ✅ Pattern: making a custom interactive element keyboard-accessible
@HostListener('keydown.enter') onEnter() { this.onClick(); }
@HostListener('keydown.space', ['$event']) onSpace(e: Event) {
  e.preventDefault(); // prevent scroll
  this.onClick();
}
```

### 17b. Focus Management

- **After dialog close**: return focus to the trigger button. MatDialog does this automatically if opened via `MatDialog.open()` — do not break this by removing the trigger from DOM.
- **After table action** (delete row, bulk update): maintain focus context. Move focus to the next row or the table header, not to the top of the page.
- **After route change**: focus the page heading `<h1>` or use `LiveAnnouncer` to announce the new page.
- **Focus trap in dialogs**: Angular CDK `FocusTrapModule` — already used by MatDialog. For custom overlays, import and use `cdkTrapFocus`.

```typescript
// ✅ Announcing dynamic content changes to screen readers
import { LiveAnnouncer } from '@angular/cdk/a11y';

constructor(private liveAnnouncer: LiveAnnouncer) {}

onDataRefreshed(count: number): void {
  this.liveAnnouncer.announce(`Table refreshed. ${count} records loaded.`);
}
```

### 17c. ARIA & Semantic HTML

**Forms — every input must have a label:**
```html
<!-- ✅ Visible label (preferred) -->
<mat-form-field>
  <mat-label>Site Name</mat-label>
  <input matInput formControlName="siteName">
</mat-form-field>

<!-- ✅ When visible label is not possible (e.g. inline filter) -->
<input matInput aria-label="Filter by site name" formControlName="siteFilter">
```

**Status indicators — never colour alone:**
```html
<!-- ❌ WRONG — colour is the only indicator -->
<span [style.color]="getConfigStatusColor(status)">●</span>

<!-- ✅ CORRECT — colour + text + aria -->
<span [style.color]="getConfigStatusColor(status)" [attr.aria-label]="'Status: ' + statusLabel">
  ● {{ statusLabel }}
</span>
```

**Tables — use PrimeNG's built-in ARIA, extend don't override:**
- `p-table` adds `role="table"`, `role="row"`, `role="cell"` automatically
- Add `aria-label` to the `<p-table>` element: `[attr.aria-label]="'Device list for ' + siteName"`
- Sort icons already announce sort state — do not replace with custom icons that lose this

**Skip navigation (add to app.component.html):**
```html
<a class="skip-link" href="#main-content">Skip to main content</a>
<!-- ... sidebar nav ... -->
<main id="main-content" tabindex="-1">
  <router-outlet></router-outlet>
</main>
```
```css
.skip-link {
  position: absolute; left: -9999px; top: auto;
  &:focus { position: fixed; top: 8px; left: 8px; z-index: 9999;
    background: var(--n-primary-color); color: white; padding: 8px 16px; border-radius: 4px; }
}
```

### 17d. Accessibility Checklist (for code review)

- [ ] All `<img>` have `alt` text (or `alt=""` if decorative)
- [ ] All form inputs have `<mat-label>` or `aria-label`
- [ ] No `<div onclick>` — use `<button>` or add `role="button"` + `tabindex="0"` + keydown
- [ ] Colour is not the sole status indicator
- [ ] Focus order follows visual order (no `tabindex` > 0)
- [ ] Dynamic content changes announced via `LiveAnnouncer` or `aria-live`
- [ ] Dialogs trap focus and return it on close
- [ ] All text meets WCAG AA contrast ratios (4.5:1 / 3:1)

---

## 18. Hardening — Real Data Resilience

> SJ operates in India across 100+ commercial buildings. Data is messy: long Hindi site names,
> 1000+ device lists, flaky IoT connections, and operators on varying screen sizes.

### 18a. Text Overflow — ENFORCED PATTERN

Any text that could exceed its container MUST use `text-ellipsis` + `pTooltip`:

```html
<!-- ✅ CORRECT — truncate + tooltip for full value -->
<td class="text-ellipsis" style="max-width: 200px;"
    [pTooltip]="row.siteName" tooltipPosition="top">
  {{ row.siteName }}
</td>

<!-- ❌ WRONG — text wraps or overflows without tooltip -->
<td>{{ row.siteName }}</td>
```

**Known long-text fields in SJ:**
- Site names (up to 60+ chars: "Bharti Realty - One Horizon Center Tower 2 - Gurgaon")
- Component names (e.g. "Chiller 3 - York YCAL0592EE - Cooling Tower Loop")
- Parameter names (e.g. "Condenser_Water_Entering_Temperature_Setpoint")
- User email addresses
- Recipe names and descriptions

### 18b. Skeleton Loading — THE standard pattern

From `recipe-configuration-list.component.ts` — this is the established pattern. Use it everywhere:

```typescript
// In component class:
skeletonRows: any[] = Array(9).fill({});  // match expected row count
isLoading$: Observable<boolean>;

// In template:
<p-table [value]="(loading$ | async) ? skeletonRows : data">
  <ng-template pTemplate="body" let-row>
    <tr>
      <td *ngIf="loading$ | async"><p-skeleton width="80%" height="16px"></p-skeleton></td>
      <td *ngIf="!(loading$ | async)">{{ row.name }}</td>
      <!-- repeat per column -->
    </tr>
  </ng-template>
</p-table>
```

**Rules:**
- Use PrimeNG `SkeletonModule` (`p-skeleton`) — never custom CSS shimmer
- Skeleton row count should match typical data count (9 for lists, 5 for dashboards)
- Skeleton width should approximate real content width (80% for names, 40% for IDs, 60% for status)
- Use `<loading-dots>` component (from `rapid-plant-builder/reusableComponents/`) for inline/button loading only

### 18c. Empty States — ENFORCED PATTERN

Every `p-table` MUST include `pTemplate="emptymessage"` with actionable guidance:

```html
<ng-template pTemplate="emptymessage">
  <tr>
    <td [attr.colspan]="columns.length" style="text-align: center; padding: 48px 16px;">
      <div class="flex-v align-center gap-12">
        <span class="material-symbols-rounded" style="font-size: 48px; color: var(--n-border-color);">
          search_off
        </span>
        <p style="font-size: 14px; color: var(--n-primary-title-color); margin: 0;">
          No devices match the current filters.
        </p>
        <p style="font-size: 13px; color: var(--n-primary-title-color); margin: 0;">
          Try clearing the Equipment Type filter or selecting a different site.
        </p>
      </div>
    </td>
  </tr>
</ng-template>
```

**Empty state vocabulary for SJ:**
```
Tables:        "No [items] match the current filters. Try [specific action]."
First run:     "No [items] configured yet. [Action button] to get started."
Error:         "Could not load [items]. [Reason]. [Retry action]."
Offline:       "IoT data unavailable — gateway may be offline. Last update: [timestamp]."
```

### 18d. Error Handling Patterns

**HTTP errors** — always routed through `HandleErrorService`:
```typescript
import { HandleErrorService } from 'app/sharedServices/handleError.service';

// In service:
this.http.get(url).pipe(
  catchError(this.handleErrorService.handleError)
);
```

`HandleErrorService` already handles:
- 401/403 → auto-logout
- 400/404/422/500 → formatted snackbar + Sentry
- 504 → "Gateway Down" message
- Default → generic server error

**Success notifications:**
```typescript
this.rapidPlantBuilderService.displaySnackbarMessage('Configuration saved successfully', 2000);
```

**Inline error states** (for forms and individual components — not just snackbar):
```html
<!-- ✅ Inline error below a form field -->
<mat-error *ngIf="form.get('setpoint').hasError('required')">
  Setpoint is required for this control mode.
</mat-error>

<!-- ✅ Inline error in a table cell -->
<td *ngIf="row.hasConflict" style="color: var(--n-sys-red);">
  Conflict: DeJoule wrote {{ row.dejouleValue }}°C but BMS reports {{ row.bmsValue }}°C
</td>
```

### 18e. Number & Date Formatting

- **Numbers**: Always use `roundOff` pipe for display. Large values (kW, BTU) should be locale-formatted with thousands separator.
- **Timestamps**: Always use `momentPipe` — never display raw epoch or ISO strings.
- **Units**: Always use `unitPreference` pipe to respect user's °C/°F preference.
- **Currency/energy**: Show 2 decimal places max for kWh, 0 for BTU.

```html
{{ value | roundOff }}              <!-- 1234.5678 → 1234.57 -->
{{ timestamp | momentPipe }}         <!-- 1681234567 → "11 Apr 2023 02:36 PM" -->
{{ temp | unitPreference:'temperature' }}  <!-- respects user's °C/°F setting -->
```

---

## 19. Highcharts Standards

> Global Highcharts config is set in `app.component.ts` → `setGlobalsForHighcharts()`.
> Interface: `GraphOptions` from `rapid-plant-builder/models/graph-options.ts`.

### 19a. SJ Chart Colour Palette

**Do NOT use Highcharts default colours.** Use the SJ palette:

```typescript
// Primary series colours (use in order)
const SJ_CHART_COLORS = [
  '#072B31',  // primary — first series
  '#28939D',  // accent — second series
  '#FF9900',  // orange — third series
  '#228B22',  // green — fourth series
  '#7A7A7A',  // neutral gray — fifth series
];

// For more than 5 series, derive at reduced opacity:
// '#072B31' at 60% → rgba(7, 43, 49, 0.6)
// '#28939D' at 60% → rgba(40, 147, 157, 0.6)
```

**Chart series at matched lightness** — all series should be equally legible. Never have one bright and one dark series that makes the bright one visually dominant.

### 19b. Chart Styling Rules

```typescript
// Standard chart title
title: {
  text: 'Chart Title',
  align: 'left',
  style: {
    fontFamily: 'Work Sans, Roboto, sans-serif',
    fontSize: '14px',
    fontWeight: '500',
    color: '#072B31',
  }
}

// Standard tooltip
tooltip: {
  backgroundColor: '#FFFFFF',
  borderColor: 'var(--n-border-color)',
  borderRadius: 4,
  shadow: { color: 'rgba(189,189,189,0.25)', offsetX: 0, offsetY: 4, width: 15 },
  style: { fontFamily: 'Work Sans, Roboto, sans-serif', fontSize: '13px', color: '#1A1A1A' },
  shared: true,
}

// Axis labels
xAxis: {
  labels: { style: { fontFamily: 'Work Sans', fontSize: '11px', color: 'rgba(0,0,0,0.6)' } }
}
```

### 19c. Chart Rules

- **No data state**: use Highcharts `noData` config with SJ-styled message:
  ```typescript
  noData: { style: { fontFamily: 'Work Sans', fontSize: '14px', color: 'rgba(0,0,0,0.6)' } }
  ```
- **Responsive**: chart container must use `height: 100%` with a parent that sets explicit height. Never hardcode pixel heights on `<highcharts-chart>`.
- **Export**: disabled globally (`exporting.enabled: false`). Use `exportToCsv()` from `app/utilities/common.util` for data export instead.
- **Credits**: hidden globally via `styles.css` (`.highcharts-credits { display: none; }`).
- **D3**: only used for specialized viz (plant SVG builder in `rapid-plant-builder`). All new charts default to Highcharts.
- **Timezone**: UTC is disabled globally (`global.useUTC: false`). Charts display local time.
- **Thousands separator**: comma, set globally (`lang.thousandsSep: ','`).

---

## 20. Impeccable Integration — Design Workflow Commands

> Install: `npx skills add pbakaus/impeccable`
> Source: https://impeccable.style/ (Apache 2.0)

This section maps Impeccable's commands to SJ-specific workflows. Use Impeccable as the
design quality layer on top of the SJ component/token system defined in §1-§15.

### 20a. One-Time Setup

Run once per project clone:
```
/impeccable teach
```
Answer the discovery questions with SJ-specific context:
- **Brand**: SmartJoules — industrial energy management, not consumer SaaS
- **Font**: Work Sans (already set globally, not an invisible default)
- **Palette**: Dark teal `#072B31`, accent `#28939D`, orange accent `#FF9900`, status colours
- **Audience**: Facility managers, energy engineers, operations teams — pragmatic, data-oriented
- **Aesthetic**: Precision operational tool. Dense data, clear hierarchy, minimal decoration
- **Anti-patterns to flag**: purple gradients, glassmorphism, dark-mode-default, card-in-card

This writes `.impeccable.md` which all subsequent commands read.

### 20b. Command Map for SJ Development

| When | Run | What it does for SJ |
|---|---|---|
| Before building a new page | `/shape` | Discovery interview: who uses this page, what data, what actions, edge cases |
| After building any new page | `/critique` | Scores against Nielsen heuristics + runs 25 anti-pattern detector |
| Before shipping | `/audit` | Checks a11y (§17), performance, token consistency, responsive |
| Legacy page touched | `/normalize` | Catches MatLegacy imports, hardcoded hex, one-off spacing, custom buttons → app-button |
| Feature functionally complete | `/polish` | Final pass: alignment, interaction states, motion, copy quality |
| Testing with real data | `/harden` | 60-char site names, 1000-device lists, Hindi text, offline IoT scenarios |
| Typography feels flat | `/typeset` | Verifies Work Sans hierarchy matches §16a scale |
| Charts/dashboard colours off | `/colorize` | Verifies series and status indicators use SJ palette (§19) |
| AI-generated component looks generic | `/quieter` | Strips purple/gradient/glow, pulls back to SJ aesthetic |
| Interface too sparse/grey | `/bolder` | Adds strategic colour using SJ palette without going garish |
| Empty states, loading, copy | `/delight` | Adds personality appropriate to operational tool (dry, precise, not playful) |

### 20c. Automated Detection

Run the Impeccable detector on built HTML:
```bash
npx impeccable detect dist/dejoule-v4/
```

This deterministically catches 25 anti-patterns (CLI layer) including:
`side-tab`, `gradient-text`, `ai-color-palette`, `dark-glow`, `nested-cards`,
`monotonous-spacing`, `everything-centered`, `bounce-easing`, `all-caps-body`,
`pure-black-white`, `gray-on-color`, `low-contrast`, `flat-type-hierarchy`,
`overused-font`, `single-font`, `icon-tile-stack`, `tight-leading`, `skipped-heading`,
`justified-text`, `tiny-text`, `wide-tracking`, `border-accent-on-rounded`, `cramped-padding`.

Two rules require browser layout: `cramped-padding`, `line-length` — use the Chrome extension or Puppeteer for these.
