# UI/UX Design Rules for Angular

**Part of AI-SDLC Skills Library**

**Purpose:** Enforce consistent, mobile-first, single-page UI/UX design in Angular applications

**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 Overview

This skill enforces three MANDATORY design rules for all Angular applications:

1. **Single Page Flow** - Always prefer single-page dashboards over multi-page navigation
2. **Mobile Responsiveness** - Mobile-first design is MANDATORY, not optional
3. **Design Consistency** - Maintain consistency across all designs

---

## 📋 The Three Rules

### Rule 1: Single Page Flow (MANDATORY)

**What it means:**
- Build dashboards as single-page applications
- Use view switching instead of routing
- Keep all dashboard functionality on one page
- Preserve state when switching views

**Why:**
- Better user experience (no page reloads)
- Faster interactions (instant updates)
- Easier state management
- Better mobile experience

**Example:**
```typescript
// ✅ GOOD: Single-page dashboard
@Component({
  template: `
    <div class="dashboard">
      <app-sidebar [selectedView]="currentView" (viewChange)="switchView($event)"></app-sidebar>
      <main>
        <app-consumption-view *ngIf="currentView === 'consumption'"></app-consumption-view>
        <app-efficiency-view *ngIf="currentView === 'efficiency'"></app-efficiency-view>
        <app-devices-view *ngIf="currentView === 'devices'"></app-devices-view>
      </main>
    </div>
  `
})
```

### Rule 2: Mobile Responsiveness (MANDATORY)

**What it means:**
- Design mobile-first (start with mobile, enhance for desktop)
- Test on real mobile devices
- Touch targets minimum 44x44px
- No horizontal scrolling
- Responsive tables (card view on mobile)
- Responsive navigation (hamburger on mobile)

**Why:**
- 60%+ users access on mobile
- Google SEO requires mobile-friendly design
- Better accessibility
- Future-proofs the application

**Breakpoints:**
- Mobile: 320px - 767px
- Tablet: 768px - 1023px
- Desktop: 1024px+

**Example:**
```scss
// Mobile-first approach
.dashboard {
  padding: 16px; // Mobile default

  @media (min-width: 768px) { // Tablet
    padding: 24px;
  }

  @media (min-width: 1024px) { // Desktop
    padding: 32px;
  }
}
```

### Rule 3: Design Consistency (MANDATORY)

**What it means:**
- Use consistent color palette
- Use consistent typography
- Use consistent spacing (8px grid system)
- Use consistent component styles
- Use consistent layout patterns
- Use icons from same set

**Why:**
- Reduces cognitive load for users
- Faster development with reusable patterns
- Easier maintenance and updates
- Professional, polished appearance

**Example:**
```scss
// Consistent spacing using 8px grid
$spacing: (
  xs: 4px,
  sm: 8px,
  md: 16px,
  lg: 24px,
  xl: 32px
);

.card {
  padding: map-get($spacing, md);
  gap: map-get($spacing, sm);
}
```

---

## 🎨 Design Patterns

### Pattern 1: Single-Page Dashboard Layout

```typescript
@Component({
  selector: 'app-dashboard',
  template: `
    <div class="dashboard">
      <!-- Sidebar navigation -->
      <app-sidebar [selectedView]="currentView" (viewChange)="onViewChange($event)"></app-sidebar>

      <!-- Main content area -->
      <main>
        <header>
          <h1>{{ currentViewTitle }}</h1>
        </header>

        <!-- Dynamic content (no routing) -->
        <ng-container [ngSwitch]="currentView">
          <app-overview-view *ngSwitchCase="'overview'"></app-overview-view>
          <app-consumption-view *ngSwitchCase="'consumption'"></app-consumption-view>
          <app-efficiency-view *ngSwitchCase="'efficiency'"></app-efficiency-view>
          <app-devices-view *ngSwitchCase="'devices'"></app-devices-view>
        </ng-container>
      </main>
    </div>
  `
})
export class DashboardComponent {
  currentView = 'overview';

  onViewChange(view: string) {
    this.currentView = view; // Just switch view, no routing
  }
}
```

### Pattern 2: Responsive Navigation

```typescript
@Component({
  selector: 'app-navigation',
  template: `
    <nav class="nav">
      <!-- Mobile: Hamburger menu -->
      <button *ngIf="isMobile" (click)="toggleMenu()">
        <mat-icon>menu</mat-icon>
      </button>

      <!-- Desktop: Horizontal menu -->
      <ul class="nav__menu" *ngIf="!isMobile">
        <li *ngFor="let item of menuItems">
          <a [routerLink]="item.link">{{ item.label }}</a>
        </li>
      </ul>

      <!-- Mobile: Slide-out menu -->
      <div class="nav__mobile-menu" *ngIf="isMobile && menuOpen">
        <ul>
          <li *ngFor="let item of menuItems">
            <a [routerLink]="item.link" (click)="closeMenu()">{{ item.label }}</a>
          </li>
        </ul>
      </div>
    </nav>
  `
})
export class NavigationComponent implements OnInit {
  isMobile = false;
  menuOpen = false;

  constructor(private breakpointObserver: BreakpointObserver) {
    this.breakpointObserver.observe(['(max-width: 767px)']).subscribe(state => {
      this.isMobile = state.matches;
    });
  }
}
```

### Pattern 3: Responsive Tables

```typescript
@Component({
  selector: 'app-data-table',
  template: `
    <div class="data-table">
      <!-- Desktop: Table view -->
      <table *ngIf="!isMobile">
        <thead>
          <tr>
            <th *ngFor="let column of columns">{{ column.header }}</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let row of data">
            <td *ngFor="let column of columns">{{ row[column.field] }}</td>
          </tr>
        </tbody>
      </table>

      <!-- Mobile: Card view -->
      <div *ngIf="isMobile">
        <div class="card" *ngFor="let row of data">
          <h3>{{ row.name }}</h3>
          <div *ngFor="let column of columns">
            <strong>{{ column.header }}:</strong> {{ row[column.field] }}
          </div>
        </div>
      </div>
    </div>
  `
})
```

---

## ✅ Design Checklist

### Single Page Flow
- [ ] Dashboard uses single-page layout
- [ ] No routing for view switching
- [ ] Instant view transitions
- [ ] State preserved between views
- [ ] Back button works (if needed)

### Mobile Responsiveness
- [ ] Works on mobile (320px+)
- [ ] Works on tablet (768px+)
- [ ] Works on desktop (1024px+)
- [ ] Touch targets ≥ 44x44px
- [ ] No horizontal scrolling
- [ ] Responsive navigation (hamburger on mobile)
- [ ] Responsive tables (cards on mobile)
- [ ] Images scale properly

### Design Consistency
- [ ] Consistent color palette
- [ ] Consistent typography
- [ ] Consistent spacing (8px grid)
- [ ] Consistent component styles
- [ ] Consistent layout patterns
- [ ] Icons from same set
- [ ] Consistent border radius
- [ ] Consistent shadows

---

## 📖 Documentation

For complete implementation details, see [SKILL.md](SKILL.md)

---

## 🚀 Quick Start

1. **Read the rules** - Understand the three mandatory principles
2. **Use the patterns** - Copy the provided code patterns
3. **Follow the checklist** - Ensure all items are checked before marking complete
4. **Test on devices** - Test on real mobile, tablet, and desktop devices

---

**Following these rules ensures consistent, mobile-first, single-page dashboards that provide excellent user experience across all devices.** 🚀
