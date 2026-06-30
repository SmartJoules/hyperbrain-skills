---
name: ui-ux-design
description: UI/UX design rules and patterns for Angular applications. Use when designing or reviewing UI, applying spacing, hierarchy, and component styling, or enforcing visual consistency in Angular apps.
---

# UI/UX Design Rules for Angular Applications

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** UI/UX design rules and patterns for Angular applications
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL UI/UX design in Angular applications:**
- Creating new dashboards and pages
- Designing user flows and interactions
- Building responsive layouts
- Ensuring design consistency
- Mobile-first development

---

## 🏗️ Core Design Principles

### Principle 1: Single Page Flow (MANDATORY)

**Rule:** **ALWAYS prefer single-page layouts over multi-page flows**

**Rationale:** Single-page dashboards provide:
- Better user experience (no page reloads)
- Faster interactions (instant updates)
- Easier state management
- Better mobile experience
- Simpler navigation

**Implementation:**

```typescript
// ✅ GOOD: Single-page dashboard with conditional rendering
@Component({
  selector: 'app-dashboard',
  template: `
    <div class="dashboard-container">
      <!-- Sidebar navigation -->
      <app-sidebar [selectedView]="currentView" (viewChange)="onViewChange($event)"></app-sidebar>

      <!-- Main content area - switches views without navigation -->
      <main class="dashboard-main">
        <app-consumption-view *ngIf="currentView === 'consumption'"></app-consumption-view>
        <app-efficiency-view *ngIf="currentView === 'efficiency'"></app-efficiency-view>
        <app-devices-view *ngIf="currentView === 'devices'"></app-devices-view>
        <app-analytics-view *ngIf="currentView === 'analytics'"></app-analytics-view>
      </main>
    </div>
  `
})
export class DashboardComponent {
  currentView: ViewType = 'consumption';

  onViewChange(view: ViewType) {
    this.currentView = view;
    // No routing, just view switching
  }
}
```

```typescript
// ❌ BAD: Multi-page navigation for dashboard
// This requires page reloads and loses state
@Component({
  selector: 'app-dashboard',
  template: `
    <nav>
      <a routerLink="/dashboard/consumption">Consumption</a>
      <a routerLink="/dashboard/efficiency">Efficiency</a>
      <a routerLink="/dashboard/devices">Devices</a>
    </nav>
    <router-outlet></router-outlet>
  `
})
```

**When to Use Single Page Flow:**

✅ **Always use for:**
- Dashboards (analytics, monitoring, reporting)
- Data visualization (charts, graphs, tables)
- Settings and configuration pages
- Forms and data entry
- Lists with drill-down details

❌ **Use routing only for:**
- Completely different contexts (admin vs user app)
- Authentication flows (login → logout)
- External links and redirects
- Deep linking to specific states

**Single Page Flow Pattern:**

```typescript
// Container component manages view state
@Component({
  selector: 'app-site-monitoring',
  template: `
    <div class="site-monitoring">
      <!-- View selector (tabs, sidebar, or dropdown) -->
      <app-view-selector
        [views]="availableViews"
        [selected]="currentView"
        (viewChange)="switchView($event)">
      </app-view-selector>

      <!-- Dynamic content area -->
      <ng-container [ngSwitch]="currentView">
        <app-overview-view *ngSwitchCase="'overview'"></app-overview-view>
        <app-consumption-view *ngSwitchCase="'consumption'"></app-consumption-view>
        <app-efficiency-view *ngSwitchCase="'efficiency'"></app-efficiency-view>
        <app-devices-view *ngSwitchCase="'devices'"></app-devices-view>
        <app-alerts-view *ngSwitchCase="'alerts'"></app-alerts-view>
      </ng-container>
    </div>
  `
})
export class SiteMonitoringComponent {
  currentView: ViewType = 'overview';
  availableViews = [
    { id: 'overview', label: 'Overview', icon: 'dashboard' },
    { id: 'consumption', label: 'Consumption', icon: 'show_chart' },
    { id: 'efficiency', label: 'Efficiency', icon: 'trending_up' },
    { id: 'devices', label: 'Devices', icon: 'devices' },
    { id: 'alerts', label: 'Alerts', icon: 'notification_important' }
  ];

  switchView(view: ViewType) {
    this.currentView = view;
    // Preserve state when switching views
    this.viewStateService.saveState(view);
  }
}
```

---

### Principle 2: Mobile Responsiveness (MANDATORY)

**Rule:** **Mobile responsiveness is MANDATORY, not optional**

**Rationale:**
- 60%+ users access on mobile devices
- Google SEO requires mobile-friendly design
- Better accessibility and user experience
- Future-proofs the application

**Breakpoint Strategy:**

```scss
// _breakpoints.scss
$breakpoints: (
  'mobile': 320px,
  'mobile-large': 375px,
  'tablet': 768px,
  'tablet-large': 1024px,
  'desktop': 1280px,
  'desktop-wide': 1440px,
  'desktop-ultra': 1920px
);

@mixin respond-to($breakpoint) {
  @if map-has-key($breakpoints, $breakpoint) {
    @media (min-width: map-get($breakpoints, $breakpoint)) {
      @content;
    }
  }
}

@mixin mobile-first {
  // Mobile-first approach (default styles)
  @content;

  // Progressive enhancement for larger screens
  @include respond-to('tablet') {
    @content;
  }
}
```

**Implementation Pattern:**

```typescript
// ✅ GOOD: Mobile-first responsive component
@Component({
  selector: 'app-dashboard',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  isMobile = false;
  isTablet = false;
  screenSize$: Observable<ScreenSize>;

  constructor(private breakpointObserver: BreakpointObserver) {}

  ngOnInit() {
    // Detect screen size changes
    this.screenSize$ = this.breakpointObserver.observe([
      '(max-width: 767px)',
      '(min-width: 768px) and (max-width: 1023px)',
      '(min-width: 1024px)'
    ]).pipe(
      map(state => {
        if (state.breakpoints('(max-width: 767px)')) {
          return ScreenSize.Mobile;
        } else if (state.breakpoints('(min-width: 768px) and (max-width: 1023px)')) {
          return ScreenSize.Tablet;
        } else {
          return ScreenSize.Desktop;
        }
      })
    );

    this.screenSize$.subscribe(size => {
      this.isMobile = size === ScreenSize.Mobile;
      this.isTablet = size === ScreenSize.Tablet;
    });
  }
}
```

```scss
// dashboard.component.scss
// Mobile-first approach (default = mobile styles)
.dashboard {
  padding: 16px;

  // Mobile layout (default)
  &__header {
    flex-direction: column;
    gap: 8px;

    &-title {
      font-size: 20px;
    }
  }

  &__grid {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  &__card {
    min-width: 100%;
  }

  // Tablet (768px+)
  @include respond-to('tablet') {
    padding: 24px;

    &__header {
      flex-direction: row;
      justify-content: space-between;
      align-items: center;

      &-title {
        font-size: 24px;
      }
    }

    &__grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 24px;
    }

    &__card {
      min-width: 0;
    }
  }

  // Desktop (1024px+)
  @include respond-to('desktop') {
    padding: 32px;

    &__grid {
      grid-template-columns: repeat(3, 1fr);
      gap: 32px;
    }
  }

  // Desktop wide (1440px+)
  @include respond-to('desktop-wide') {
    &__grid {
      grid-template-columns: repeat(4, 1fr);
    }
  }
}
```

**Responsive Navigation Pattern:**

```typescript
// ✅ GOOD: Responsive navigation
@Component({
  selector: 'app-navigation',
  template: `
    <nav class="nav">
      <!-- Mobile: Hamburger menu -->
      <button
        class="nav__hamburger"
        *ngIf="isMobile"
        (click)="toggleMenu()"
        aria-label="Toggle menu">
        <mat-icon>menu</mat-icon>
      </button>

      <!-- Logo -->
      <a class="nav__logo" routerLink="/dashboard">
        <img src="logo.svg" alt="Logo" />
      </a>

      <!-- Desktop: Horizontal menu -->
      <ul class="nav__menu" *ngIf="!isMobile">
        <li *ngFor="let item of menuItems">
          <a [routerLink]="item.link" [class.active]="isActive(item.link)">
            <mat-icon>{{ item.icon }}</mat-icon>
            <span>{{ item.label }}</span>
          </a>
        </li>
      </ul>

      <!-- Mobile: Slide-out menu -->
      <div class="nav__mobile-menu" *ngIf="isMobile && menuOpen" [@slideIn]>
        <ul class="nav__mobile-menu-list">
          <li *ngFor="let item of menuItems">
            <a [routerLink]="item.link" (click)="closeMenu()">
              <mat-icon>{{ item.icon }}</mat-icon>
              <span>{{ item.label }}</span>
            </a>
          </li>
        </ul>
      </div>
    </nav>
  `
})
export class NavigationComponent {
  isMobile = false;
  menuOpen = false;
  menuItems = [
    { link: '/dashboard', label: 'Dashboard', icon: 'dashboard' },
    { link: '/sites', label: 'Sites', icon: 'location_on' },
    { link: '/devices', label: 'Devices', icon: 'devices' },
    { link: '/analytics', label: 'Analytics', icon: 'analytics' }
  ];

  constructor(private breakpointObserver: BreakpointObserver) {
    this.breakpointObserver
      .observe(['(max-width: 767px)'])
      .subscribe(state => {
        this.isMobile = state.matches;
        this.menuOpen = false; // Close menu when switching to mobile
      });
  }

  toggleMenu() {
    this.menuOpen = !this.menuOpen;
  }

  closeMenu() {
    this.menuOpen = false;
  }

  isActive(link: string): boolean {
    return this.router.url.startsWith(link);
  }
}
```

**Responsive Tables:**

```typescript
// ✅ GOOD: Responsive table for mobile
@Component({
  selector: 'app-data-table',
  template: `
    <div class="data-table">
      <!-- Desktop: Table view -->
      <table class="data-table__desktop" *ngIf="!isMobile">
        <thead>
          <tr>
            <th *ngFor="let column of columns">{{ column.header }}</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let row of data">
            <td *ngFor="let column of columns">
              {{ row[column.field] }}
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Mobile: Card view -->
      <div class="data-table__mobile" *ngIf="isMobile">
        <div class="data-table__card" *ngFor="let row of data">
          <div class="data-table__card-header">
            <h3>{{ row[nameField] }}</h3>
          </div>
          <div class="data-table__card-body">
            <div *ngFor="let column of columns" class="data-table__card-row">
              <span class="label">{{ column.header }}:</span>
              <span class="value">{{ row[column.field] }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  `
})
export class DataTableComponent implements OnInit {
  @Input() data: any[];
  @Input() columns: Column[];
  @Input() nameField = 'name';
  isMobile = false;

  constructor(private breakpointObserver: BreakpointObserver) {
    this.breakpointObserver
      .observe(['(max-width: 767px)'])
      .subscribe(state => {
        this.isMobile = state.matches;
      });
  }
}
```

---

### Principle 3: Design Consistency (MANDATORY)

**Rule:** **Maintain consistency across all designs and components**

**Rationale:**
- Reduces cognitive load for users
- Faster development with reusable patterns
- Easier maintenance and updates
- Professional, polished appearance

**Consistency Areas:**

#### 1. Color Palette Consistency

```scss
// _colors.scss
// Define consistent color palette
$colors: (
  primary: (
    base: #1976D2,
    light: #42A5F5,
    dark: #1565C0,
    contrast: #FFFFFF
  ),
  secondary: (
    base: #424242,
    light: #757575,
    dark: #212121,
    contrast: #FFFFFF
  ),
  success: #4CAF50,
  warning: #FF9800,
  error: #F44336,
  info: #2196F3
);

// Use consistent color variables
.button {
  background-color: map-get($map-get($colors, primary), base);
  color: map-get($map-get($colors, primary), contrast);

  &:hover {
    background-color: map-get($map-get($colors, primary), dark);
  }
}

.alert {
  &--success {
    background-color: map-get($colors, success);
    color: #FFFFFF;
  }

  &--error {
    background-color: map-get($colors, error);
    color: #FFFFFF;
  }
}
```

#### 2. Typography Consistency

```scss
// _typography.scss
$font-families: (
  primary: 'Roboto, sans-serif',
  mono: 'Roboto Mono, monospace'
);

$font-sizes: (
  h1: 32px,
  h2: 28px,
  h3: 24px,
  h4: 20px,
  h5: 16px,
  h6: 14px,
  body: 14px,
  small: 12px
);

$font-weights: (
  light: 300,
  regular: 400,
  medium: 500,
  semibold: 600,
  bold: 700
);

$line-heights: (
  tight: 1.2,
  normal: 1.5,
  relaxed: 1.8
);

// Use consistent typography
h1 {
  font-family: map-get($font-families, primary);
  font-size: map-get($font-sizes, h1);
  font-weight: map-get($font-weights, bold);
  line-height: map-get($line-heights, tight);
}

p {
  font-family: map-get($font-families, primary);
  font-size: map-get($font-sizes, body);
  font-weight: map-get($font-weights, regular);
  line-height: map-get($line-heights, normal);
}
```

#### 3. Spacing Consistency

```scss
// _spacing.scss
// Use 8px grid system for consistent spacing
$spacing: (
  xs: 4px,
  sm: 8px,
  md: 16px,
  lg: 24px,
  xl: 32px,
  xxl: 48px
);

// Use consistent spacing
.card {
  padding: map-get($spacing, md);
  gap: map-get($spacing, sm);

  &__header {
    margin-bottom: map-get($spacing, md);
  }

  &__body {
    padding: map-get($spacing, md) 0;
  }

  &__footer {
    margin-top: map-get($spacing, lg);
    padding-top: map-get($spacing, md);
  }
}
```

#### 4. Component Consistency

```typescript
// ✅ GOOD: Consistent button component
@Component({
  selector: 'app-button',
  template: `
    <button
      [ngClass]="['button', `button--${variant}`, `button--${size}`]"
      [disabled]="disabled || loading"
      (click)="onClick.emit($event)">
      <mat-icon *ngIf="icon && !loading" class="button__icon">{{ icon }}</mat-icon>
      <mat-spinner *ngIf="loading" class="button__spinner" diameter="16"></mat-spinner>
      <span class="button__text" *ngIf="text">{{ text }}</span>
    </button>
  `,
  styleUrls: ['./button.component.scss']
})
export class ButtonComponent {
  @Input() variant: 'primary' | 'secondary' | 'text' = 'primary';
  @Input() size: 'small' | 'medium' | 'large' = 'medium';
  @Input() icon?: string;
  @Input() text?: string;
  @Input() disabled = false;
  @Input() loading = false;
  @Output() onClick = new EventEmitter<MouseEvent>();
}
```

```scss
// button.component.scss
// Consistent button styles across entire app
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: none;
  border-radius: 4px;
  font-family: 'Roboto', sans-serif;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;

  // Variants
  &--primary {
    background-color: #1976D2;
    color: #FFFFFF;

    &:hover:not(:disabled) {
      background-color: #1565C0;
    }
  }

  &--secondary {
    background-color: #424242;
    color: #FFFFFF;

    &:hover:not(:disabled) {
      background-color: #212121;
    }
  }

  &--text {
    background-color: transparent;
    color: #1976D2;

    &:hover:not(:disabled) {
      background-color: rgba(25, 118, 210, 0.08);
    }
  }

  // Sizes
  &--small {
    padding: 8px 16px;
    font-size: 12px;
    height: 32px;
  }

  &--medium {
    padding: 10px 20px;
    font-size: 14px;
    height: 40px;
  }

  &--large {
    padding: 12px 24px;
    font-size: 16px;
    height: 48px;
  }

  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
}
```

#### 5. Layout Consistency

```scss
// _layout.scss
// Consistent layout patterns
.container {
  max-width: 1440px;
  margin: 0 auto;
  padding: 0 16px;

  @include respond-to('tablet') {
    padding: 0 24px;
  }

  @include respond-to('desktop') {
    padding: 0 32px;
  }
}

.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;

  &__header {
    padding: map-get($spacing, md);
    border-bottom: 1px solid #E0E0E0;
  }

  &__content {
    flex: 1;
    padding: map-get($spacing, md);
  }

  &__footer {
    padding: map-get($spacing, md);
    border-top: 1px solid #E0E0E0;
  }
}
```

---

## 🎨 Design System Components

### 1. Dashboard Card Pattern

```typescript
// ✅ GOOD: Consistent dashboard card
@Component({
  selector: 'app-dashboard-card',
  template: `
    <div class="dashboard-card">
      <div class="dashboard-card__header">
        <mat-icon *ngIf="icon">{{ icon }}</mat-icon>
        <h3 class="dashboard-card__title">{{ title }}</h3>
        <button
          class="dashboard-card__menu"
          *ngIf="showMenu"
          (click)="menuOpened.emit()"
          aria-label="More options">
          <mat-icon>more_vert</mat-icon>
        </button>
      </div>

      <div class="dashboard-card__content">
        <ng-content></ng-content>
      </div>

      <div class="dashboard-card__footer" *ngIf="footer">
        {{ footer }}
      </div>
    </div>
  `,
  styleUrls: ['./dashboard-card.component.scss']
})
export class DashboardCardComponent {
  @Input() title: string;
  @Input() icon?: string;
  @Input() footer?: string;
  @Input() showMenu = false;
  @Output() menuOpened = new EventEmitter<void>();
}
```

```scss
// dashboard-card.component.scss
.dashboard-card {
  background: #FFFFFF;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  padding: 16px;
  transition: box-shadow 0.2s ease;

  &:hover {
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
  }

  &__header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 16px;

    mat-icon {
      color: #1976D2;
    }
  }

  &__title {
    flex: 1;
    font-size: 16px;
    font-weight: 600;
    color: #424242;
    margin: 0;
  }

  &__menu {
    padding: 4px;
    background: transparent;
    border: none;
    cursor: pointer;
    border-radius: 50%;

    &:hover {
      background: rgba(0, 0, 0, 0.04);
    }
  }

  &__content {
    min-height: 100px;
  }

  &__footer {
    margin-top: 16px;
    padding-top: 16px;
    border-top: 1px solid #E0E0E0;
    font-size: 12px;
    color: #757575;
  }
}
```

### 2. Responsive Grid Pattern

```typescript
// ✅ GOOD: Responsive grid with consistent breakpoints
@Component({
  selector: 'app-responsive-grid',
  template: `
    <div [ngClass]="['responsive-grid', `responsive-grid--${columns}`]">
      <ng-content></ng-content>
    </div>
  `,
  styleUrls: ['./responsive-grid.component.scss']
})
export class ResponsiveGridComponent {
  @Input() columns: 1 | 2 | 3 | 4 = 3;
  @Input() gap: 'small' | 'medium' | 'large' = 'medium';
}
```

```scss
// responsive-grid.component.scss
.responsive-grid {
  display: grid;
  gap: 16px;

  // Mobile: 1 column
  grid-template-columns: 1fr;

  // Tablet: 2 columns
  @include respond-to('tablet') {
    grid-template-columns: repeat(2, 1fr);
    gap: 24px;
  }

  // Desktop: Dynamic columns
  @include respond-to('desktop') {
    &--1 {
      grid-template-columns: 1fr;
    }
    &--2 {
      grid-template-columns: repeat(2, 1fr);
    }
    &--3 {
      grid-template-columns: repeat(3, 1fr);
    }
    &--4 {
      grid-template-columns: repeat(4, 1fr);
    }

    gap: 32px;
  }
}
```

---

## 📐 Responsive Design Checklist

Before marking any UI component complete:

### Mobile (320px - 767px)
- [ ] Content fits on small screens
- [ ] Text is readable without zooming
- [ ] Buttons are touch-friendly (min 44x44px)
- [ ] Navigation is hamburger menu
- [ ] Tables convert to card view
- [ ] Images scale properly
- [ ] No horizontal scrolling
- [ ] Forms are easy to use on mobile

### Tablet (768px - 1023px)
- [ ] Layout adapts to 2-column grid
- [ ] Navigation is horizontal menu
- [ ] Touch targets are appropriate size
- [ ] Content is properly spaced

### Desktop (1024px+)
- [ ] Layout uses maximum available space
- [ ] Hover states work properly
- [ ] Keyboard navigation works
- [ ] High DPI displays are supported

---

## 🎯 Design Patterns for Single Page Dashboards

### Pattern 1: Sidebar Navigation

```typescript
// ✅ GOOD: Sidebar navigation for single-page dashboard
@Component({
  selector: 'app-dashboard-layout',
  template: `
    <div class="dashboard-layout">
      <!-- Sidebar (collapsible on mobile) -->
      <aside class="dashboard-layout__sidebar" [class.collapsed]="sidebarCollapsed">
        <div class="sidebar__header">
          <img src="logo.svg" alt="Logo" class="sidebar__logo" />
          <button
            class="sidebar__toggle"
            (click)="toggleSidebar()"
            aria-label="Toggle sidebar">
            <mat-icon>menu</mat-icon>
          </button>
        </div>

        <nav class="sidebar__nav">
          <a
            *ngFor="let item of menuItems"
            class="sidebar__nav-item"
            [class.active]="activeView === item.id"
            (click)="selectView(item.id)">
            <mat-icon>{{ item.icon }}</mat-icon>
            <span *ngIf="!sidebarCollapsed">{{ item.label }}</span>
          </a>
        </nav>
      </aside>

      <!-- Main content area -->
      <main class="dashboard-layout__main">
        <header class="main__header">
          <h1>{{ currentViewTitle }}</h1>
          <div class="header__actions">
            <app-button icon="notifications" variant="text"></app-button>
            <app-button icon="account_circle" variant="text"></app-button>
          </div>
        </header>

        <div class="main__content">
          <ng-container [ngSwitch]="activeView">
            <app-overview-view *ngSwitchCase="'overview'"></app-overview-view>
            <app-consumption-view *ngSwitchCase="'consumption'"></app-consumption-view>
            <app-efficiency-view *ngSwitchCase="'efficiency'"></app-efficiency-view>
            <app-devices-view *ngSwitchCase="'devices'"></app-devices-view>
          </ng-container>
        </div>
      </main>
    </div>
  `
})
export class DashboardLayoutComponent {
  sidebarCollapsed = false;
  activeView = 'overview';

  menuItems = [
    { id: 'overview', label: 'Overview', icon: 'dashboard' },
    { id: 'consumption', label: 'Consumption', icon: 'show_chart' },
    { id: 'efficiency', label: 'Efficiency', icon: 'trending_up' },
    { id: 'devices', label: 'Devices', icon: 'devices' }
  ];

  toggleSidebar() {
    this.sidebarCollapsed = !this.sidebarCollapsed;
  }

  selectView(viewId: string) {
    this.activeView = viewId;
  }

  get currentViewTitle(): string {
    return this.menuItems.find(item => item.id === this.activeView)?.label || '';
  }
}
```

### Pattern 2: Tab-Based Navigation

```typescript
// ✅ GOOD: Tab-based navigation for related views
@Component({
  selector: 'app-tabbed-dashboard',
  template: `
    <div class="tabbed-dashboard">
      <mat-tab-group [selectedIndex]="activeTabIndex" (selectedTabChange)="onTabChange($event)">
        <mat-tab *ngFor="let tab of tabs">
          <ng-template matTabLabel>
            <mat-icon>{{ tab.icon }}</mat-icon>
            <span>{{ tab.label }}</span>
          </ng-template>
          <ng-container *ngComponentOutlet="tab.component"></ng-container>
        </mat-tab>
      </mat-tab-group>
    </div>
  `
})
export class TabbedDashboardComponent {
  activeTabIndex = 0;

  tabs = [
    { label: 'Overview', icon: 'dashboard', component: OverviewViewComponent },
    { label: 'Consumption', icon: 'show_chart', component: ConsumptionViewComponent },
    { label: 'Efficiency', icon: 'trending_up', component: EfficiencyViewComponent }
  ];

  onTabChange(event: any) {
    this.activeTabIndex = event.index;
  }
}
```

---

## ✅ Design Quality Checklist

Before marking any design work complete:

### Single Page Flow
- [ ] Dashboard uses single-page layout (no routing for views)
- [ ] View switching is instant (no page reload)
- [ ] State is preserved when switching views
- [ ] Back button works correctly (if needed)
- [ ] URL updates for deep linking (optional)

### Mobile Responsiveness
- [ ] Works on mobile (320px+)
- [ ] Works on tablet (768px+)
- [ ] Works on desktop (1024px+)
- [ ] Touch targets are minimum 44x44px
- [ ] Text is readable without zooming
- [ ] No horizontal scrolling
- [ ] Images scale properly
- [ ] Forms work on mobile

### Design Consistency
- [ ] Uses consistent color palette
- [ ] Uses consistent typography
- [ ] Uses consistent spacing (8px grid)
- [ ] Uses consistent component styles
- [ ] Uses consistent layout patterns
- [ ] Icons are from same set
- [ ] Border radius is consistent
- [ ] Shadows are consistent

### Accessibility
- [ ] Keyboard navigation works
- [ ] Screen reader friendly
- [ ] Color contrast meets WCAG AA
- [ ] Focus indicators visible
- [ ] ARIA labels present
- [ ] Alt text for images

---

## 📚 Related Skills

- **jouletrack-angular** - Angular Container/Presenter pattern
- **superpowers-brainstorming** - AI-powered design planning
- **state-management** - Managing UI state in single-page apps
- **tdd-workflow** - Test-driven development for UI components

---

**Following these rules ensures consistent, mobile-first, single-page dashboards that provide excellent user experience across all devices.** 🚀
