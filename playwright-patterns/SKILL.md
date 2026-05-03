# Playwright E2E Testing

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** End-to-end testing with Playwright for DeJoule applications
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL E2E testing** in DeJoule products:
- Testing user flows across multiple pages
- Validating critical user journeys
- Regression testing before releases
- Cross-browser testing
- Visual regression testing
- API testing alongside UI tests

---

## 🏗️ Playwright Architecture

### Test Organization

```
e2e/
├── tests/                    # Test files
│   ├── auth/               # Authentication tests
│   │   ├── login.spec.ts
│   │   └── logout.spec.ts
│   ├── dashboard/          # Dashboard tests
│   │   ├── consumption.spec.ts
│   │   ├── efficiency.spec.ts
│   │   └── devices.spec.ts
│   ├── devices/            # Device management tests
│   │   ├── list.spec.ts
│   │   ├── command.spec.ts
│   │   └── telemetry.spec.ts
│   └── recipes/             # Recipe execution tests
│       ├── execute.spec.ts
│       └── status.spec.ts
├── pages/                   # Page Object Model
│   ├── BasePage.ts
│   ├── DashboardPage.ts
│   ├── DevicePage.ts
│   └── LoginPage.ts
├── fixtures/               # Test data and utilities
│   ├── test-data.ts
│   ├── auth-fixtures.ts
│   └── device-fixtures.ts
├── utils/                  # Helper functions
│   ├── api-helpers.ts
│   ├── db-helpers.ts
│   └── test-helpers.ts
└── playwright.config.ts     # Playwright configuration
```

---

## 🎨 Page Object Model Pattern

### Base Page

```typescript
import { Page, Locator } from '@playwright/test';

/**
 * @description Base page with common functionality
 */
export class BasePage {
  constructor(protected page: Page) {}

  /**
   * @description Navigate to URL
   */
  async navigate(url: string): Promise<void> {
    await this.page.goto(url);
    await this.waitForLoad();
  }

  /**
   * @description Wait for page to be fully loaded
   */
  protected async waitForLoad(): Promise<void> {
    await this.page.waitForLoadState('networkidle');
    await this.page.waitForLoadState('domcontentloaded');
  }

  /**
   * @description Wait for element to be visible
   */
  protected async waitForVisible(selector: string): Promise<Locator> {
    await this.page.waitForSelector(selector, { state: 'visible' });
    return this.page.locator(selector);
  }

  /**
   * @description Click element
   */
  protected async click(selector: string): Promise<void> {
    await this.waitForVisible(selector);
    await this.page.click(selector);
  }

  /**
   * @description Fill input
   */
  protected async fill(selector: string, value: string): Promise<void> {
    await this.waitForVisible(selector);
    await this.page.fill(selector, value);
  }

  /**
   * @description Get text content
   */
  protected async getText(selector: string): Promise<string> {
    const element = await this.waitForVisible(selector);
    return await element.textContent() || '';
  }

  /**
   * @description Wait for API response
   */
  protected async waitForAPI(urlPattern: RegExp): Promise<void> {
    await this.page.waitForResponse(
      response => urlPattern.test(response.url()),
      { timeout: 10000 }
    );
  }
}
```

### Dashboard Page

```typescript
import { Page, expect } from '@playwright/test';
import { BasePage } from './BasePage';

/**
 * @description Dashboard page object
 */
export class DashboardPage extends BasePage {
  /**
   * @description Page URL
   */
  static readonly url = '/dashboard/iah-del';

  /**
   * @description Selectors
   */
  private readonly selectors = {
    consumptionChart: 'app-energy-chart',
    efficiencyCard: '.efficiency-card',
    deviceList: '.device-list',
    siteSelector: '.site-selector',
    dateRangePicker: 'p-calendar',
  };

  /**
   * @description Navigate to dashboard
   */
  async gotoDashboard(siteId: string = 'iah-del'): Promise<void> {
    await this.navigate(`/dashboard/${siteId}`);
  }

  /**
   * @description Get consumption value
   */
  async getConsumptionValue(): Promise<string> {
    const text = await this.getText('.consumption-value');
    return text.trim();
  }

  /**
   * @description Get efficiency percentage
   */
  async getEfficiencyValue(): Promise<string> {
    const text = await this.getText('.efficiency-value');
    return text.trim();
  }

  /**
   * @description Select site from dropdown
   */
  async selectSite(siteName: string): Promise<void> {
    await this.click(this.selectors.siteSelector);
    await this.page.click(`text=${siteName}`);
    await this.waitForAPI(/api\/dashboard/);
  }

  /**
   * @description Set date range
   */
  async setDateRange(startDate: string, endDate: string): Promise<void> {
    await this.click(this.selectors.dateRangePicker);
    // ... date selection logic
  }

  /**
   * @description Wait for chart to render
   */
  async waitForChart(): Promise<void> {
    await this.waitForVisible(this.selectors.consumptionChart);
    await this.page.waitForTimeout(1000); // Wait for animation
  }

  /**
   * @description Verify device is displayed
   */
  async verifyDeviceDisplayed(deviceName: string): Promise<boolean> {
    const deviceElement = this.page.locator(`.device-list >> text="${deviceName}"`);
    return await deviceElement.isVisible();
  }
}
```

### Login Page

```typescript
import { Page, expect } from '@playwright/test';
import { BasePage } from './BasePage';

/**
 * @description Login page object
 */
export class LoginPage extends BasePage {
  static readonly url = '/login';

  private readonly selectors = {
    emailInput: '#email',
    passwordInput: '#password',
    loginButton: 'button[type="submit"]',
    errorMessage: '.error-message',
  };

  /**
   * @description Login with credentials
   */
  async login(email: string, password: string): Promise<void> {
    await this.fill(this.selectors.emailInput, email);
    await this.fill(this.selectors.passwordInput, password);
    await this.click(this.selectors.loginButton);

    // Wait for navigation to dashboard
    await this.page.waitForURL(/\/dashboard\/.+/);
  }

  /**
   * @description Get error message
   */
  async getErrorMessage(): Promise<string> {
    const element = await this.page.waitForSelector(this.selectors.errorMessage, {
      timeout: 5000,
    });
    return await element.textContent() || '';
  }

  /**
   * @description Verify login successful
   */
  async verifyLoginSuccessful(): Promise<boolean> {
    const currentUrl = this.page.url();
    return currentUrl.includes('/dashboard/');
  }
}
```

---

## 🧪 Test Patterns

### Authentication Test

```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { DashboardPage } from '../pages/DashboardPage';

test.describe('Authentication', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
  });

  test('should login successfully with valid credentials', async ({ page }) => {
    // Arrange
    await loginPage.navigate(LoginPage.url);

    // Act
    await loginPage.login('test@dejoule.com', 'password123');

    // Assert
    await expect(dashboardPage.verifyLoginSuccessful()).toBe(true);
  });

  test('should show error with invalid credentials', async ({ page }) => {
    // Arrange
    await loginPage.navigate(LoginPage.url);

    // Act
    await loginPage.login('invalid@test.com', 'wrongpassword');

    // Assert
    const errorMessage = await loginPage.getErrorMessage();
    expect(errorMessage).toContain('Invalid credentials');
  });

  test('should redirect to login if not authenticated', async ({ page }) => {
    // Act
    await page.goto('/dashboard/iah-del');

    // Assert
    await expect(page).toHaveURL(/\/login/);
  });
});
```

### Dashboard Test

```typescript
import { test, expect } from '@playwright/test';
import { DashboardPage } from '../pages/DashboardPage';
import { APIHelper } from '../utils/api-helpers';

test.describe('Dashboard', () => {
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    // Setup: Login and navigate to dashboard
    const loginPage = new LoginPage(page);
    await loginPage.login('test@dejoule.com', 'password123');
    dashboardPage = new DashboardPage(page);
  });

  test('should display consumption data', async () => {
    // Act
    await dashboardPage.gotoDashboard();

    // Assert
    const consumption = await dashboardPage.getConsumptionValue();
    expect(consumption).toBeTruthy();
    expect(consumption).toMatch(/\d+ kWh/);
  });

  test('should display efficiency metrics', async () => {
    // Act
    await dashboardPage.gotoDashboard();

    // Assert
    const efficiency = await dashboardPage.getEfficiencyValue();
    expect(efficiency).toBeTruthy();
    expect(efficiency).toMatch(/\d+\.\d+/); // e.g., "0.65"
  });

  test('should display device list', async () => {
    // Act
    await dashboardPage.gotoDashboard();

    // Assert
    const isDeviceDisplayed = await dashboardPage.verifyDeviceDisplayed('Chiller-1');
    expect(isDeviceDisplayed).toBe(true);
  });

  test('should update data when site is changed', async () => {
    // Act
    await dashboardPage.gotoDashboard();
    await dashboardPage.selectSite('Mumbai-Factory');

    // Assert
    await dashboardPage.waitForChart();
    const consumption = await dashboardPage.getConsumptionValue();
    expect(consumption).toBeTruthy();
  });
});
```

### Device Command Test

```typescript
import { test, expect } from '@playwright/test';
import { DevicePage } from '../pages/DevicePage';
import { DeviceFixtures } from '../fixtures/device-fixtures';

test.describe('Device Commands', () => {
  let devicePage: DevicePage;

  test.beforeEach(async ({ page }) => {
    // Setup: Login and navigate to device page
    const loginPage = new LoginPage(page);
    await loginPage.login('test@dejoule.com', 'password123');
    devicePage = new DevicePage(page);
  });

  test('should send setpoint command successfully', async ({ page, request }) => {
    // Mock API
    let apiCalled = false;
    await page.route('**/api/devices/*/command', route => {
      apiCalled = true;
      return route.fulfill({
        status: 200,
        body: JSON.stringify({
          success: true,
          data: { commandId: 'cmd-123' }
        }),
      });
    });

    // Act
    await devicePage.gotoDevice('chiller-1');
    await devicePage.setSetpoint('leaving_water_temperature', 7.0);

    // Assert
    expect(apiCalled).toBe(true);
    const successMessage = await devicePage.getSuccessMessage();
    expect(successMessage).toContain('Command sent successfully');
  });

  test('should handle command failure gracefully', async ({ page }) => {
    // Mock API to return error
    await page.route('**/api/devices/*/command', route => {
      return route.fulfill({
        status: 500,
        body: JSON.stringify({
          success: false,
          error: 'Device not responding'
        }),
      });
    });

    // Act
    await devicePage.gotoDevice('chiller-1');
    await devicePage.setSetpoint('leaving_water_temperature', 7.0);

    // Assert
    const errorMessage = await devicePage.getErrorMessage();
    expect(errorMessage).toContain('Device not responding');
  });

  test('should validate setpoint range', async ({ page }) => {
    // Act
    await devicePage.gotoDevice('chiller-1');
    await devicePage.setSetpoint('leaving_water_temperature', 15.0); // Too high

    // Assert
    const validationError = await devicePage.getValidationError();
    expect(validationError).toContain('must be between 5 and 12');
  });
});
```

### Recipe Execution Test

```typescript
import { test, expect } from '@playwright/test';
import { RecipePage } from '../pages/RecipePage';
import { RecipeFixtures } from '../fixtures/recipe-fixtures';

test.describe('Recipe Execution', () => {
  let recipePage: RecipePage;

  test.beforeEach(async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.login('test@dejoule.com', 'password123');
    recipePage = new RecipePage(page);
  });

  test('should execute optimization recipe successfully', async ({ page }) => {
    // Act
    await recipePage.gotoRecipes();
    await recipePage.selectRecipe('Chiller Optimization');
    await recipePage.executeRecipe();

    // Assert
    const status = await recipePage.getExecutionStatus();
    expect(status).toBe('running');

    // Wait for completion
    await recipePage.waitForCompletion(60000); // 1 minute timeout

    const finalStatus = await recipePage.getExecutionStatus();
    expect(finalStatus).toBe('completed');

    // Verify results
    const results = await recipePage.getExecutionResults();
    expect(results).toHaveProperty('energySavings');
    expect(results.energySavings).toBeGreaterThan(0);
  });

  test('should abort recipe execution', async ({ page }) => {
    // Act
    await recipePage.gotoRecipes();
    await recipePage.selectRecipe('Chiller Optimization');
    await recipePage.executeRecipe();
    await recipePage.abortRecipe();

    // Assert
    const status = await recipePage.getExecutionStatus();
    expect(status).toBe('aborted');
  });
});
```

---

## 📊 Test Data Generation

### Using DeJoule Knowledge Base

```typescript
import { Site, Device, Component } from '../types/dejoule.types';
import { random } from '../utils/test-helpers';

/**
 * @description Test data factory
 */
export class TestDataFactory {
  /**
   * @description Generate test site
   */
  static generateSite(overrides?: Partial<Site>): Site {
    return {
      id: random.uuid(),
      name: 'Test Site',
      location: {
        lat: 19.0760,
        lng: 72.8777,
        address: 'Test Address',
      },
      timezone: 'Asia/Kolkata',
      created_at: new Date(),
      updated_at: new Date(),
      ...overrides,
    };
  }

  /**
   * @description Generate test device
   */
  static generateDevice(siteId: string, overrides?: Partial<Device>): Device {
    return {
      id: random.uuid(),
      site_id: siteId,
      name: 'Test Chiller',
      type: 'chiller',
      controllerid: 'controller-1',
      properties: {
        capacity: 500,
        make: 'TestMake',
        model: 'TestModel',
      },
      created_at: new Date(),
      ...overrides,
    };
  }

  /**
   * @description Generate test telemetry data
   */
  static generateTelemetry(deviceId: string): any[] {
    const now = Date.now();
    return Array.from({ length: 24 }, (_, i) => ({
      timestamp: new Date(now - i * 3600000).toISOString(),
      readings: {
        energy_kwh: 100 + Math.random() * 50,
        power_kw: 45 + Math.random() * 10,
        entering_water_temp_c: 10 + Math.random() * 2,
        leaving_water_temp_c: 7 + Math.random() * 2,
      },
    }));
  }

  /**
   * @description Generate test command
   */
  static generateCommand(deviceId: string): any {
    return {
      timestamp: new Date().toISOString(),
      request_id: random.uuid(),
      site_id: 'test-site',
      device_id: deviceId,
      command: 'set_setpoint',
      parameters: {
        setpoint_type: 'leaving_water_temperature',
        value: 7.0,
        unit: 'celsius',
      },
    };
  }
}
```

---

## 🎯 Test Generation from DeJoule KB

### AI-Powered Test Case Generation

When a new feature is added, AI automatically generates E2E tests based on:

**1. Analyze Feature from DeJoule KB**
```typescript
// AI reads from DeJoule Knowledge Base
feature: "New SEC Dashboard widget"

// KB provides:
// - Widget uses consumption-chart component
// - Data from /api/dashboard/:siteId/sec endpoint
// - Displays SEC (Specific Energy Consumption)
// - Updates every 5 minutes
// - Has drill-down to device level
```

**2. Generate Test Cases**
```typescript
test.describe('SEC Dashboard Widget', () => {
  test('should display SEC value on dashboard', async () => {
    // Test: Widget displays
    // - Navigate to dashboard
    // - Verify SEC widget is visible
    // - Verify SEC value is displayed
    // - Verify units (kWh/TR)
  });

  test('should update SEC every 5 minutes', async () => {
    // Test: Auto-refresh
    // - Record initial SEC value
    // - Wait for refresh cycle
    // - Verify SEC value updated
  });

  test('should allow drill-down to device level', async () => {
    // Test: Drill-down interaction
    // - Click on SEC widget
    // - Navigate to device breakdown
    // - Verify device-level SEC displayed
  });

  test('should show alarm when SEC exceeds threshold', async () => {
    // Test: Threshold alert
    // - Mock API to return high SEC
    // - Verify alert banner displayed
    // - Verify alert severity
  });
});
```

**3. Test Data from KB**
```typescript
// Use realistic test data from KB
testData = {
  site: 'iah-del',
  device: 'chiller-1',
  sec: 0.75, // Normal
  highSec: 1.2, // Alert threshold
  timestamp: '2026-05-03T10:30:00Z',
};
```

---

## 🔧 Configuration

### Playwright Config

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e/tests',

  // Timeout
  timeout: 30000,

  // Retries
  retries: process.env.CI ? 2 : 0,

  // Workers
  workers: process.env.CI ? 1 : undefined,

  // Reporter
  reporter: [
    ['html'],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['allure-playwright'], // If using Allure
  ],

  // Use
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:4200',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  // Projects
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
});
```

---

## 🚀 Execution Patterns

### Running Tests

```bash
# Run all tests
npx playwright test

# Run specific test file
npx playwright test e2e/tests/dashboard/consumption.spec.ts

# Run tests in headed mode
npx playwright test --headed

# Run tests in debug mode
npx playwright test --debug

# Run tests on specific browser
npx playwright test --project=firefox

# Run tests with grep filter
npx playwright test --grep "dashboard"
```

### CI/CD Integration

```yaml
# GitHub Actions
name: E2E Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 20

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Run Playwright tests
        run: npx playwright test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
```

---

## ✅ Quality Checklist

Before marking tests complete:
- [ ] Page Object Model used
- [ ] Tests independent (no shared state)
- [ ] Arrange-Act-Assert pattern followed
- [ ] Proper waits used (no hard-coded sleeps)
- [ ] Assertions meaningful and specific
- [ ] Error cases tested
- [ ] Test data from KB (realistic values)
- [ ] Cross-browser tests (if applicable)
- [ ] CI/CD integration configured
- [ ] Video recordings on failure
- [ ] Screenshots on failure

---

## 📚 Related Skills

- **TDD Workflow** - Test-first development
- **DeJoule Knowledge Base** - Domain context
- **Backend Knowledge Base** - API understanding
- **IoT Knowledge Base** - Device understanding

---

**Remember:** E2E tests should cover critical user journeys and provide confidence that the system works end-to-end. Combine with unit and integration tests for comprehensive coverage.
