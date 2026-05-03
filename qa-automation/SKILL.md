# QA Automation Knowledge Base

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Complete QA automation knowledge for automated testing
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL QA automation** in DeJoule products:
- Creating automated test suites
- Implementing test generation from features
- Setting up CI/CD testing pipelines
- Quality assurance and regression testing
- Integrating with Playwright for E2E testing

---

## 🏗️ QA Automation Architecture

### Complete QA Workflow

```
Feature Development
       ↓
[AI Superpowers: Requirements Analysis]
- What is the feature?
- What are the acceptance criteria?
- What are the edge cases?
       ↓
[Test Generation: AI + KB]
- Generate unit tests from code
- Generate integration tests from API specs
- Generate E2E tests from user flows
       ↓
[Test Execution: Playwright + Custom]
- Run unit tests (Jasmine/Jest)
- Run integration tests (Supertest)
- Run E2E tests (Playwright)
       ↓
[Quality Gates]
- 80% coverage requirement
- All tests passing
- No critical bugs
       ↓
[Reporting]
- Test coverage report
- Test execution report
- Bug report generation
```

---

## 🤖 AI-Powered Test Generation

### How It Works

**1. Feature Analysis**
```
Developer: "Add a new widget showing real-time SEC"

AI: [Activates DeJoule KB]
    "Based on the JouleTRACK dashboard architecture:

    Feature: SEC Widget
    - Component: consumption-chart (existing)
    - API: /api/dashboard/:siteId/sec
    - Update Frequency: 5 minutes
    - Displays: kWh/TR (Specific Energy Consumption)

    I'll generate tests for:
    1. Component unit tests (Jasmine)
    2. Service integration tests (Supertest)
    3. E2E tests (Playwright)"
```

**2. Test Generation Rules**

Based on DeJoule Knowledge Base:

**Unit Tests**
```typescript
// For Angular Components
- Test ngOnInit lifecycle
- Test data fetching (observables)
- Test data transformation
- Test error handling
- Test user interactions

// For Services
- Test API calls (mocked)
- Test data transformation
- Test error handling
- Test caching logic
```

**Integration Tests**
```typescript
// For API Endpoints
- Test happy path
- Test error responses (404, 500)
- Test validation errors
- Test authentication
- Test rate limiting
```

**E2E Tests**
```typescript
// For User Flows
- Test login → dashboard → feature
- Test data display
- Test user interactions
- Test error scenarios
- Test edge cases
```

---

## 🧪 Test Templates

### Component Unit Test Template (Auto-Generated)

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { of } from 'rxjs';

import { SecWidgetComponent } from './sec-widget.component';
import { DashboardService } from '../../services/dashboard.service';

describe('SecWidgetComponent', () => {
  let component: SecWidgetComponent;
  let fixture: ComponentFixture<SecWidgetComponent>;
  let dashboardServiceSpy: jasmine.SpyObj<DashboardService>;
  let httpMock: HttpTestingController;

  beforeEach(async () => {
    // Mock service
    dashboardServiceSpy = jasmine.createSpyObj('DashboardService', {
      getSEC: jasmine.createSpy('getSEC').and.returnValue(of({ value: 0.75 })),
    });

    await TestBed.configureTestingModule({
      declarations: [SecWidgetComponent],
      providers: [
        { provide: DashboardService, useValue: dashboardServiceSpy },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(SecWidgetComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should display SEC value', () => {
    const compiled = fixture.nativeElement;
    const secValue = compiled.querySelector('.sec-value')?.textContent;

    expect(secValue).toContain('0.75');
  });

  it('should fetch SEC on init', () => {
    expect(dashboardServiceSpy.getSEC).toHaveBeenCalledWith('iah-del');
  });

  it('should handle API errors gracefully', () => {
    dashboardServiceSpy.getSEC.and.returnValue(
      throwError(() => new Error('API Error'))
    );

    fixture.detectChanges();

    const compiled = fixture.nativeElement;
    const errorMessage = compiled.querySelector('.error-message')?.textContent;

    expect(errorMessage).toContain('Failed to load SEC data');
  });

  it('should update SEC every 5 minutes', (done) => {
    jasmine.clock().install();
    const interval = 5 * 60 * 1000; // 5 minutes

    component.ngOnInit();
    tick(0); // Initial fetch
    expect(dashboardServiceSpy.getSEC).toHaveBeenCalledWith('iah-del');

    tick(interval); // Refresh after 5 minutes
    expect(dashboardServiceSpy.getSEC).toHaveBeenCalledTimes(2);

    jasmine.clock().uninstall();
    done();
  });
});
```

### API Integration Test Template (Auto-Generated)

```typescript
import request from 'supertest';
import { app } from '../../app';
import { setupTestDatabase, teardownTestDatabase } from '../fixtures/db-setup';

describe('SEC API Integration Tests', () => {
  let authToken: string;

  beforeAll(async () => {
    // Setup test database
    await setupTestDatabase();

    // Get auth token
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@dejoule.com', password: 'password' });
    authToken = loginResponse.body.token;
  });

  afterAll(async () => {
    await teardownTestDatabase();
  });

  describe('GET /api/dashboard/:siteId/sec', () => {
    it('should return SEC value for valid site', async () => {
      const response = await request(app)
        .get('/api/dashboard/iah-del/sec')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('value');
      expect(response.body.data.value).toBeGreaterThan(0);
    });

    it('should return 404 for non-existent site', async () => {
      const response = await request(app)
        .get('/api/dashboard/non-existent/sec')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should return 401 without auth token', async () => {
      const response = await request(app)
        .get('/api/dashboard/iah-del/sec')
        .expect(401);

      expect(response.body.success).toBe(false);
    });

    it('should return SEC in kWh/TR format', async () => {
      const response = await request(app)
        .get('/api/dashboard/iah-del/sec')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveProperty('unit');
      expect(response.body.data.unit).toBe('kWh/TR');
    });

    it('should cache response for 5 minutes', async () => {
      const response1 = await request(app)
        .get('/api/dashboard/iah-del/sec')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const response2 = await request(app)
        .get('/api/dashboard/iah-del/sec')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Verify cache hit (second request faster)
      // This would require timing assertions
    });
  });
});
```

### E2E Test Template (Auto-Generated)

```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { DashboardPage } from '../pages/DashboardPage';
import { TestDataFactory } from '../fixtures/test-data.factory';

test.describe('SEC Widget E2E Tests', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
  });

  test.beforeAll(async () => {
    // Setup: Seed database with test data
    await TestDataFactory.seedSite('iah-del');
    await TestDataFactory.seedTelemetry('iah-del', 'chiller-1', {
      timestamp: '2026-05-03T10:30:00Z',
      sec: 0.75,
    });
  });

  test('should display SEC widget on dashboard', async ({ page }) => {
    // Arrange
    await loginPage.login('test@dejoule.com', 'password123');

    // Act
    await dashboardPage.gotoDashboard('iah-del');

    // Assert
    await expect(page.locator('.sec-widget')).toBeVisible();
    await expect(page.locator('.sec-value')).toContainText('0.75');
  });

  test('should update SEC value every 5 minutes', async ({ page }) => {
    // Arrange
    await loginPage.login('test@dejoule.com', 'password123');
    await dashboardPage.gotoDashboard('iah-del');

    // Act - Get initial value
    const initialSEC = await dashboardPage.getSECValue();

    // Update database with new SEC
    await TestDataFactory.updateTelemetry('iah-del', 'chiller-1', { sec: 0.80 });

    // Wait for refresh (simulated)
    await page.waitForTimeout(5000); // Wait 5 minutes (in test, just 5 seconds)

    // Assert
    const updatedSEC = await dashboardPage.getSECValue();
    expect(updatedSEC).not.toBe(initialSEC);
  });

  test('should show alert when SEC exceeds threshold', async ({ page }) => {
    // Arrange
    await loginPage.login('test@dejoule.com', 'password123');

    // Update database with high SEC
    await TestDataFactory.updateTelemetry('iah-del', 'chiller-1', { sec: 1.2 });

    // Act
    await dashboardPage.gotoDashboard('iah-del');

    // Assert
    await expect(page.locator('.alert-banner')).toBeVisible();
    await expect(page.locator('.alert-banner')).toContainText('high SEC');
  });

  test('should allow drill-down to device level SEC', async ({ page }) => {
    // Arrange
    await loginPage.login('test@dejoule.com', 'password123');
    await dashboardPage.gotoDashboard('iah-del');

    // Act
    await page.click('.sec-widget');

    // Assert
    await expect(page.locator('.device-breakdown')).toBeVisible();
    await expect(page.locator('.chiller-1-sec')).toContainText('0.75');
  });

  test('should display SEC for different time ranges', async ({ page }) => {
    // Arrange
    await loginPage.login('test@dejoule.com', 'password123');
    await dashboardPage.gotoDashboard('iah-del');

    // Act
    await dashboardPage.setDateRange('2026-05-01', '2026-05-07');

    // Assert
    await expect(page.locator('.sec-value')).toBeVisible();
    const secValue = await dashboardPage.getSECValue();
    expect(secValue).toBeTruthy();
  });
});
```

---

## 🔄 Test Generation Pipeline

### Step 1: Analyze Feature

```typescript
/**
 * AI analyzes new feature from multiple sources:
 * 1. DeJoule KB - Domain knowledge
 * 2. Backend KB - API specifications
 * 3. IoT KB - Device behavior
 * 4. Frontend KB - Component patterns
 */
```

### Step 2: Generate Test Suite

```typescript
/**
 * AI generates comprehensive test suite:
 * 1. Unit tests for each component/service
 * 2. Integration tests for API endpoints
 * 3. E2E tests for user flows
 * 4. Edge case tests
 * 5. Error handling tests
 */
```

### Step 3: Execute Tests

```bash
# Run all generated tests
npm test                 # Unit tests
npm run test:integration # Integration tests
npx playwright test     # E2E tests
```

### Step 4: Generate Report

```typescript
/**
 * Generate comprehensive test report:
 * 1. Test coverage report
 * 2. Test execution report
 * 3. Bug report
 * 4. Recommendations
 */
```

---

## 📊 Test Coverage

### Coverage Targets

```yaml
Unit Tests:
  - Services: 90%+ coverage
  - Components: 80%+ coverage
  - Repositories: 85%+ coverage
  - Transformers: 95%+ coverage

Integration Tests:
  - API endpoints: 100%
  - Database operations: 100%
  - External APIs: 80%+

E2E Tests:
  - Critical user journeys: 100%
  - Happy paths: 100%
  - Error scenarios: 80%+
  - Edge cases: 60%+
```

### Coverage Reporting

```bash
# Generate coverage report
npm run test:coverage

# View in browser
npx http-server ./coverage -p 8080
```

---

## 🚨 Regression Testing

### Test Priorities

**P0 - Critical (Must Pass)**
- Login/logout
- Dashboard loading
- Device commands
- Recipe execution

**P1 - High (Should Pass)**
- Data visualization
- Reporting
- Settings

**P2 - Medium (Nice to Have)**
- Export features
- Advanced filtering
- Custom views

---

## 🔧 Configuration

### Test Configuration

```javascript
// playwright.config.js
module.exports = {
  testDir: './e2e/tests',
  timeout: 30000,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: process.env.BASE_URL,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
};
```

---

## 📚 Related Skills

- **Playwright Patterns** - E2E test implementation
- **TDD Workflow** - Test-first development
- **DeJoule Knowledge Base** - Domain context
- **Backend Knowledge Base** - API understanding
- **Frontend Knowledge Base** - UI patterns

---

**This knowledge base enables AI-powered QA automation that generates comprehensive tests based on complete understanding of the DeJoule ecosystem.**
