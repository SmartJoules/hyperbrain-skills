---
name: jouletrack-angular
description: Angular development patterns and conventions for the JouleTRACK frontend. Use for all Angular work in JouleTRACK: creating components, services, and modules, building dashboards, charts, and forms, using PrimeNG-first UI components, using Boxicons-first icons, and following the project's OnPush, RxJS, analytics, and styling conventions.
---

# JouleTRACK Angular Development

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Angular patterns and conventions for JouleTRACK frontend
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL Angular development** in JouleTRACK:
- Creating new components, services, modules
- Implementing features and user stories
- Adding or changing user interactions that must be tracked in Google Analytics
- Working with dashboards, charts, forms
- State management and data flow
- Testing Angular code

---

## 📈 Google Analytics Rule (Mandatory for FE Interactions)

Every new or changed meaningful JouleTRACK user interaction must emit a Google Analytics event through the existing analytics/telemetry abstraction. Search the repo first for the current helper/service before adding a new one.

Track:
- button/link/card clicks
- form submit/save/delete/cancel actions
- filter, date range, tab, drawer, modal, toggle, and chart drilldown changes
- exports/downloads
- route/deep-link interactions
- critical workflow success/failure states shown to the user

Do not track:
- hover/mousemove/scroll noise
- every keystroke
- polling/render cycles
- raw form values or free text
- emails, phone numbers, tokens, credentials, or other PII/secrets

Event naming should be stable and product-readable:

```text
<module>_<object>_<action>
plant_schedule_recipe_link_click
dashboard_filter_apply
smart_alert_subscription_unsubscribe
```

Prefer payloads like:

```typescript
{
  siteId,
  module: 'plant_schedule',
  action: 'recipe_link_click',
  status: 'success',
}
```

Verify analytics in tests with a spy when practical; otherwise include it in the manual QA checklist.

---

## 🧩 PrimeNG + Boxicons Rule (Mandatory for UI)

For new or changed JouleTRACK UI:

- Use PrimeNG as the default component library. Reach for `p-table`, `p-dropdown`, `p-multiSelect`, `pTooltip`, `p-skeleton`, paginator, tabs, accordion, toast, overlay, chips, and related PrimeNG modules before custom markup or Angular Material.
- Use SmartJoules internal wrappers where they are already standardized: `app-button`, `png-table`, `severity-chips`, `segment-toggle-switch`, and other repo-local shared components.
- Use Boxicons for new icons: action icons, navigation icons, status icons, feature icons, and empty-state icons.
- Keep Boxicons styled with `currentColor`, consistent sizing, and accessible labels/tooltips for icon-only controls.
- Do not introduce new Angular Material components or Material Symbols when PrimeNG/internal components and Boxicons can cover the need. Existing legacy Material usage can remain when touching unrelated code.

---

## 🏗️ Angular Architecture

### Module Structure (JouleTRACK Pattern)
```
src/app/
├── app/                        # Feature modules (@itsatif's pattern)
│   ├── rapid-plant-builder/    # Example: Complex feature module
│   │   ├── rapid-plant-builder.module.ts
│   │   ├── rapid-plant-builder.component.ts
│   │   ├── rapid-plant-builder-routing.module.ts
│   │   ├── component-store/    # Component stores (NgRx lite)
│   │   ├── factory-class/      # Factory classes
│   │   ├── dialogs/            # Dialog components
│   │   ├── dynamic-components/ # Dynamically created components
│   │   ├── reusableComponents/ # Feature-specific reusable components
│   │   └── models/             # Feature models
│   ├── dashboard/             # Dashboard features
│   ├── map/                   # Map functionality
│   └── [other features]
├── sharedServices/            # Cross-cutting services
│   ├── config.service.ts      # Site config, current site$
│   ├── user.service.ts        # User management
│   ├── auth.service.ts        # Authentication
│   └── [other services]
├── models/                    # Shared models
│   ├── site.ts
│   ├── device.ts
│   └── component.ts
├── utilities/                 # Utility functions
│   └── common.util.ts
└── reducers/                  # NgRx store
```

### Module Import Pattern (From RapidPlantBuilderModule)

**ALWAYS follow this exact import structure:**

```typescript
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

// PrimeNG imports (primary UI library)
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { CalendarModule } from 'primeng/calendar';
import { TooltipModule } from 'primeng/tooltip';

// Angular Material imports (secondary, specific components only)
import { MatLegacyButtonModule as MatButtonModule } from '@angular/material/legacy-button';
import { MatLegacyCardModule as MatCardModule } from '@angular/material/legacy-card';
import { MatLegacyInputModule as MatInputModule } from '@angular/material/legacy-input';
import { MatLegacySelectModule as MatSelectModule } from '@angular/material/legacy-select';

// Feature-specific imports
import { RoutingModule } from './feature-routing.module';
import { FeatureComponent } from './feature.component';

// Local feature imports
import { SubComponent1 } from './sub-component1/sub-component1.component';
import { SubComponent2 } from './sub-component2/sub-component2.component';

@NgModule({
  declarations: [
    // ALL components used in this feature (nested or not)
    FeatureComponent,
    SubComponent1,
    SubComponent2,
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    // PrimeNG modules
    TableModule,
    ButtonModule,
    // Material modules
    MatButtonModule,
    MatCardModule,
    MatInputModule,
    // Feature modules
    RoutingModule,
  ],
  providers: [
    // Feature-specific services
    FeatureService,
    // Component stores
    FeatureStore,
  ],
  exports: [
    // Components to export for other features
    SubComponent1,
  ],
})
export class FeatureModule {}
```

---

## 🎨 Component Patterns

### Component Pattern (JouleTRACK Style - @itsatif's exact pattern)

**ALWAYS follow this structure from RapidPlantBuilderComponent:**

```typescript
import { Component, OnInit, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { filter, map, switchMap, tap } from 'rxjs/operators';
import { combineLatest } from 'rxjs';

// Services
import { ConfigService } from 'app/sharedServices/config.service';
import { UserService } from 'app/sharedServices/user.service';

// Models
import { Site } from 'app/models/site';

/**
 * @description Component documentation
 * @selector Selector name
 */
@Component({
  selector: 'app-feature',
  templateUrl: './feature.component.html',
  styleUrls: ['./feature.component.css'],
  encapsulation: ViewEncapsulation.None,
})
export class FeatureComponent implements OnInit {
  /**
   * @description The View Model Stream for storing site and route streams
   * @type {Observable<{site: Site, params: any}>}
   */
  vm$: Observable<any>;

  /**
   * @description The current subscribed site's siteId
   * @type {string}
   */
  siteId: string = '';

  /**
   * @description The form with filter controls
   * @type {FormGroup}
   */
  featureForm: FormGroup = new FormGroup({
    status: new FormControl(0),
  });

  /**
   * @description Creates an instance of FeatureComponent.
   * @param {ConfigService} configService - Service for handling configuration settings.
   * @param {UserService} userService - Service for handling user-related functionality.
   * @param {ActivatedRoute} route - Angular route service for handling route information.
   * @param {Router} router - Angular router service for navigation.
   */
  constructor(
    private configService: ConfigService,
    private userService: UserService,
    private route: ActivatedRoute,
    private router: Router,
  ) {}

  /**
   * @description Lifecycle hook when the component will mount
   */
  ngOnInit(): void {
    this.vm$ = combineLatest([
      this.configService.currentSite$,
      this.route.params,
      this.userService.user$,
    ]).pipe(
      switchMap(([site, param, user]) =>
        of({ site, param, user }).pipe(
          filter(({ site, param }) => site.siteId === param.siteId),
          tap(({ site }): void => {
            this.siteId = site.siteId;
          }),
          map(({ site, param, user }) => ({ site, param, user })),
        ),
      ),
    );
  }

  /**
   * @description Helper method documentation
   * @param {string} param Parameter description
   * @returns {void} Return type description
   */
  helperMethod(param: string): void {
    // Implementation
  }
}
```

### Key Documentation Requirements:
- **JSDoc comments** on all classes, methods, and properties
- **Type annotations** on ALL properties (even inferred ones)
- **Return types** explicitly declared (`: void`, `: Observable<any>`)
- **Parameter descriptions** in constructor and methods
- **Use `@description` tag** for main purpose
- **Use `@type` tag** for property types

---

## 📡 Data Layer Patterns

### Facade Pattern

**ALWAYS use facades for state management:**

```typescript
@Injectable({ providedIn: 'root' })
export class EnergyFacade {
  constructor(
    private energyService: EnergyService,
    private transformer: DataTransformer
  ) {}

  getEnergyData(): Observable<EnergyViewModel> {
    return this.energyService.fetchData().pipe(
      map(dto => this.transformer.toDomain(dto)),
      map(domain => this.transformer.toViewModel(domain)),
      shareReplay(1)
    );
  }

  refreshData(): void {
    this.energyService.invalidateCache();
  }
}
```

### Service Pattern (JouleTRACK Style - @itsatif's exact pattern)

**ALWAYS follow this structure from ConfigService:**

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { filter, map, take } from 'rxjs/operators';
import { select, Store } from '@ngrx/store';
import * as fromRoot from 'app/reducers';
import { MatLegacySnackBar as MatSnackBar } from '@angular/material/legacy-snack-bar';
import { HandleErrorService } from './handleError.service';

@Injectable({
  providedIn: 'root',
})
export class FeatureService {
  /**
   * @description Observable to emit device type map from store.
   */
  devicesByType$: Observable<{ [key: string]: Device[] }>;

  /**
   * @description Observable to emit current site from store.
   */
  currentSite$: Observable<Site>;

  /**
   * @description Observable to emit current site list from store.
   */
  siteList$: Observable<Site[]>;

  /**
   * @description Constructor to initialize dependencies and store variables.
   * @param {HttpClient} http - Angular HttpClient for HTTP requests.
   * @param {Store} store - Application store service for state management.
   * @param {MatSnackBar} snackBar - Angular Material Snackbar for displaying notifications.
   * @param {HandleErrorService} handleErrorService - Service for handling errors.
   */
  constructor(
    private http: HttpClient,
    private store: Store<fromRoot.State>,
    public snackBar: MatSnackBar,
    public handleErrorService: HandleErrorService,
  ) {
    /**
     * Fetch data from NgRx store using select pattern
     * Always use filter() to remove undefined values
     */
    this.devicesByType$ = this.store.pipe(
      select(fromRoot.getDeviceTypesState),
      filter((result): boolean => result !== undefined),
    );

    this.currentSite$ = this.store.pipe(
      select(fromRoot.getSiteState),
      filter((result: Site): boolean => result !== undefined),
    );

    this.siteList$ = this.store.pipe(
      select(fromRoot.getSitesState),
      filter((result: Site[]): boolean => result !== undefined),
    );
  }

  /**
   * @description Method documentation
   * @param {string} siteId - The site ID to fetch data for
   * @returns {Observable<any>} - Observable of fetched data
   */
  fetchData(siteId: string): Observable<any> {
    return this.http.get<any>(`/api/data/${siteId}`).pipe(
      catchError((err: any) => {
        this.handleErrorService.handleError(err);
        return of(null);
      })
    );
  }
}
```

### Key Service Pattern Requirements:
- **JSDoc documentation** on all properties and methods
- **Type annotations** on all properties
- **Public services** (snackBar, handleErrorService) for component access
- **Store.select() pattern** with filter() to remove undefined
- **Observable<T>** return types explicitly declared
- **catchError** with HandleErrorService

---

## 🔄 Observable Handling

### ALWAYS Use Cleanup

```typescript
// ✅ CORRECT: With cleanup
data$ = this.service.getData().pipe(
  takeUntil(this.destroy$),
  distinctUntilChanged(),
  catchError(err => this.handleError(err))
);

ngOnDestroy() {
  this.destroy$.next();
  this.destroy$.complete();
}

// ❌ WRONG: No cleanup
data$ = this.service.getData().subscribe();
```

### RxJS Operators Guide

- **Sequential:** `concatMap` - must maintain order
- **Cancelling:** `switchMap` - cancel previous requests
- **Parallel:** `mergeMap` - order doesn't matter
- **Caching:** `shareReplay(1)` - share across subscribers
- **Deduplication:** `distinctUntilChanged()` - avoid redundant emits

---

## 📊 Chart Integration (Apache ECharts)

### Chart Builder Pattern

```typescript
@Injectable({ providedIn: 'root' })
export class EnergyChartBuilder {
  build(data: EnergyData): EChartOption {
    return {
      xAxis: {
        type: 'category',
        data: data.timestamps
      },
      yAxis: {
        type: 'value',
        name: 'Energy (kWh)'
      },
      series: [{
        type: 'line',
        data: data.values,
        smooth: true,
        areaStyle: {}
      }],
      tooltip: {
        trigger: 'axis'
      },
      legend: {
        data: ['Energy Consumption']
      }
    };
  }
}
```

### Component Usage

```typescript
export class EnergyChartComponent implements OnDestroy {
  private chart?: echarts.ECharts;

  constructor(
    private chartBuilder: EnergyChartBuilder,
    private el: ElementRef,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit() {
    this.chart = echarts.init(this.el.nativeElement);
    this.updateChart();

    // Responsive resize
    fromEvent(window, 'resize').pipe(
      debounceTime(200),
      takeUntil(this.destroy$)
    ).subscribe(() => this.chart?.resize());
  }

  updateChart() {
    const option = this.chartBuilder.build(this.data);
    this.chart?.setOption(option);
  }

  ngOnDestroy() {
    this.chart?.dispose();
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```

---

## 🔐 Site Context Handling

### ALWAYS Subscribe to Site Changes

```typescript
@Component({
  selector: 'app-site-aware',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SiteAwareComponent implements OnInit, OnDestroy {
  destroy$ = new Subject<void>();
  currentSite$: Observable<string>;

  constructor(
    private configService: ConfigService,
    private dataService: DataService
  ) {}

  ngOnInit() {
    this.currentSite$ = this.configService.currentSite$;

    // Reload data when site changes
    this.configService.currentSite$.pipe(
      switchMap(siteId => this.dataService.getSiteData(siteId)),
      takeUntil(this.destroy$)
    ).subscribe(data => {
      this.handleSiteData(data);
    });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```

---

## 🎯 Data Transformation Pipeline

### DTO → Domain → ViewModel

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
@Injectable({ providedIn: 'root' })
export class EnergyTransformer {
  toDomain(dto: EnergyDto): EnergyDomain {
    return {
      timestamp: new Date(dto.timestamp),
      power: dto.kw,
      energy: dto.kwh
    };
  }

  toViewModel(domain: EnergyDomain): EnergyViewModel {
    return {
      displayTime: domain.timestamp.toLocaleTimeString(),
      powerFormatted: `${domain.power.toFixed(2)} kW`,
      energyFormatted: `${domain.energy.toFixed(2)} kWh`
    };
  }
}
```

---

## 🚨 Mandatory Rules

### Component Rules
- ✅ **ALWAYS** use `ViewEncapsulation.None` (JouleTRACK standard)
- ✅ **ALWAYS** implement `OnInit` (and `OnDestroy` if needed)
- ✅ **ALWAYS** add JSDoc comments with `@description` tag
- ✅ **ALWAYS** declare property types explicitly (even if inferred)
- ✅ **ALWAYS** use `public` for services that components need
- ✅ **ALWAYS** use template and styleUrls in @Component decorator
- ✅ **NEVER** leave properties implicitly public (use private/protected)

### Service Rules
- ✅ **ALWAYS** provide in root when singleton
- ✅ **ALWAYS** declare all Observable properties with explicit types
- ✅ **ALWAYS** use `filter()` to remove undefined values from store
- ✅ **ALWAYS** make helper services public (snackBar, handleErrorService)
- ✅ **ALWAYS** add JSDoc for constructor parameters
- ✅ **NEVER** return `any` type - use explicit interfaces

### Observable Rules
- ✅ **ALWAYS** use `combineLatest` for multiple observables
- ✅ **ALWAYS** use `switchMap` for site/route changes
- ✅ **ALWAYS** use `filter()` to validate site matches
- ✅ **ALWAYS** use `tap()` for side effects (setting local properties)
- ✅ **ALWAYS** use `map()` for final view model transformation
- ✅ **NEVER** subscribe in constructor (use ngOnInit)

### Module Rules
- ✅ **ALWAYS** declare ALL components used in feature (even nested ones)
- ✅ **ALWAYS** import both FormsModule and ReactiveFormsModule
- ✅ **ALWAYS** use PrimeNG as primary UI library
- ✅ **ALWAYS** use Boxicons for new icons
- ✅ **ALWAYS** use Angular Material only for legacy/specific repo-standard components
- ✅ **ALWAYS** export reusable components in exports array
- ✅ **NEVER** use ViewEncapsulation.Emulated (use None)

### Import Rules
- ✅ **ALWAYS** group imports: Angular → RxJS → Services → Models
- ✅ **ALWAYS** use named imports (no `import * from`)
- ✅ **ALWAYS** import from 'app/...' for project files
- ✅ **ALWAYS** import Observable and operators separately
- ✅ **NEVER** use default imports

### Documentation Rules
- ✅ **ALWAYS** add JSDoc comments above classes
- ✅ **ALWAYS** use `@description` for main purpose
- ✅ **ALWAYS** use `@type` for property types
- ✅ **ALWAYS** use `@param` for constructor/method parameters
- ✅ **ALWAYS** use `@returns` for method return types
- ✅ **NEVER** skip documentation on public methods

---

## 📝 Naming Conventions (JouleTRACK Style)

### Component Files
- `kebab-case.component.ts` - Component file
- `kebab-case.component.html` - Template file
- `kebab-case.component.css` - Styles file
- `kebab-case-routing.module.ts` - Routing module

### Service Files
- `kebab-case.service.ts` - Service file (in sharedServices/ or feature/)
- `kebab-case.store.ts` - Component store (in component-store/)

### Module Files
- `kebab-case.module.ts` - Feature module file

### Class Names
- PascalCase for classes: `RapidPlantBuilderComponent`
- camelCase for properties: `siteId`, `currentSite$`

### Observable Names
- Append `$` to all Observable properties: `vm$`, `siteId$`, `systems$`
- Use descriptive names: `currentSite$` not `site$`

### Method Names
- camelCase for methods: `createBreadCrumbs()`, `ngOnInit()`
- Use verb-noun pattern: `fetchData()`, `loadSite()`, `updateView()`

---

## 🧪 Testing Patterns

### Unit Test Template

```typescript
describe('EnergyComponent', () => {
  let component: EnergyComponent;
  let fixture: ComponentFixture<EnergyComponent>;
  let facadeMock: jasmine.SpyObj<EnergyFacade>;

  beforeEach(async () => {
    facadeMock = jasmine.createSpyObj('EnergyFacade', ['getEnergyData']);

    await TestBed.configureTestingModule({
      declarations: [EnergyComponent],
      providers: [
        { provide: EnergyFacade, useValue: facadeMock }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(EnergyComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load energy data on init', () => {
    const mockData = of({ value: 100 });
    facadeMock.getEnergyData.and.returnValue(mockData);

    component.ngOnInit();
    fixture.detectChanges();

    expect(facadeMock.getEnergyData).toHaveBeenCalled();
  });
});
```

---

## 📋 Common Tasks

### Creating a New Feature Module

```bash
# Generate module
ng generate module features/my-feature --module app

# Generate components
ng generate component features/my-feature/containers/my-feature
ng generate component features/my-feature/presenters/my-feature-presenter

# Generate service
ng generate service features/my-feature/services/my-feature

# Generate facade
ng generate service features/my-feature/facades/my-feature
```

### Adding PrimeNG Components

```typescript
// Import in module
import { TableModule } from 'primeng/table';
import { ChartModule } from 'primeng/chart';

@NgModule({
  imports: [
    TableModule,
    ChartModule
  ]
})
export class MyFeatureModule { }
```

### Adding Boxicons

Use the repo's existing Boxicons setup if present. If the package is not installed yet, prefer the scoped official packages from Boxicons and avoid unofficial wrappers.

```html
<i class="bx bx-filter-alt" aria-hidden="true"></i>
<button app-button type="button" pTooltip="Filter alerts" aria-label="Filter alerts">
  <i class="bx bx-filter-alt" aria-hidden="true"></i>
</button>
```

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Memory leaks**
- **Solution:** Always use `takeUntil(this.destroy$)` and complete it in `ngOnDestroy`

**Issue: Data not updating**
- **Solution:** Check `OnPush` change detection, use `async` pipe

**Issue: Site data not refreshing**
- **Solution:** Subscribe to `configService.currentSite$` and reload data

**Issue: Chart not rendering**
- **Solution:** Call `chart.resize()` on window resize events

---

## 📚 Additional Resources

### Internal Documentation
- `AI_CONTEXT.md` - System architecture
- `docs/ai/frontend-dashboard-v2.md` - Frontend patterns
- `kiro_steering.md` - Coding standards

### External Resources
- Angular Documentation: https://angular.dev
- RxJS Documentation: https://rxjs.dev
- PrimeNG Documentation: https://primeng.org
- Apache ECharts: https://echarts.apache.org

---

## 🔄 Common PR Feedback Patterns

### Code Quality Issues

**Remove console.log statements**
- ✅ Use `console.error` for errors only
- ❌ Remove all `console.log` statements from production code
- Use proper logging services for production debugging

**Comment style and documentation**
- ✅ Use JSDoc style (`/** */`) for function documentation
- ❌ Don't use verbose section comments like `// ─── Section ───`
- Keep comments short and readable - don't write essays in comments
- Remove all commented-out code before PR

**Optional chaining vs validation**
- ✅ Use `configurator.isValidValue()` for array/object validation instead of optional chaining
- ❌ Don't use `?.data?.filter()` - use proper validation
- Example: `configurator.isValidValue(data) ? data.filter(...) : []`

**Type safety**
- ✅ Always add explicit types to variables
- ✅ Use null coalescing operator (`??`) for fallback values
- ❌ Don't leave variables untyped
- Example: `const siteId: string | null = this.offlineConfigService.siteId ?? 'default';`

**Service configuration**
- ✅ Use `providedIn: 'root'` for singleton services
- ❌ Don't add singleton services to module `providers: []`
- If service is `providedIn: 'root'`, it's redundant to add to module providers

### Configuration and Constants

**Constants cleanup**
- ✅ Remove commented-out values (they're not being used)
- ❌ Don't leave code commented out - either use it or remove it
- Example: If `'suh-hyd'` is commented in excludeSites array, remove it entirely

**Keep it simple**
- ✅ Remove verbose explanatory comments from constants files
- ✅ Make code self-documenting with good naming
- ❌ Don't add essays explaining temporary values

### File Organization

**Documentation files**
- ✅ Remove temporary documentation files from codebase
- ❌ Don't commit design docs, implementation plans, or QA test plans
- Keep documentation in wiki, not in `docs/` folder

**HTML templates**
- ✅ Remove all commented-out HTML
- ❌ Don't leave commented UI elements in templates

### Build Artifacts

**ngsw-config.json**
- ✅ Let Angular CLI manage service worker config
- ❌ Don't manually modify hash values in ngsw-config.json
- This file should not be in PR diffs (it's a build artifact)

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] `ChangeDetectionStrategy.OnPush` set
- [ ] `ngOnDestroy` with cleanup implemented
- [ ] All observables have `takeUntil`
- [ ] All observables have `catchError`
- [ ] No `any` types used
- [ ] Site context subscribed (if applicable)
- [ ] Container/Presenter pattern followed
- [ ] Unit tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** Consistency over cleverness. Follow these patterns and your code will integrate seamlessly with the existing JouleTRACK codebase.
