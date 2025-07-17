# Playwright E2E Tests - Quick Start Guide

## Prerequisites

1. Ensure Rails server can run in test mode:
   ```bash
   RAILS_ENV=test bundle exec rails db:create db:migrate
   ```

2. Install dependencies (already done):
   ```bash
   npm install
   npx playwright install
   ```

## Running Tests

### Run all tests
```bash
npm run e2e
```

### Run specific test file
```bash
npx playwright test e2e/tests/auth/login.spec.ts
```

### Run in UI mode (recommended for development)
```bash
npm run e2e:ui
```

### Debug a specific test
```bash
npm run e2e:debug e2e/tests/auth/login.spec.ts
```

### Generate test code with Codegen
```bash
npm run e2e:codegen http://localhost:3000
```

## Test Structure

- **Smoke Tests**: Basic functionality checks
  ```bash
  npx playwright test smoke
  ```

- **Authentication Tests**: Login, logout, password reset
  ```bash
  npx playwright test auth/
  ```

## Troubleshooting

### Rails server not starting
- Check that port 3001 is available
- Ensure test database is created and migrated
- Check logs in test-results/ directory

### Tests failing to find elements
- Use Playwright UI mode to debug
- Check that test data is being created properly
- Verify selectors in browser DevTools

### Authentication tests failing
- Ensure test users are created in global setup
- Check that Devise is configured for test environment
- Verify CSRF tokens are handled correctly

## Writing New Tests

1. Create test file in appropriate directory under `e2e/tests/`
2. Import necessary page objects and fixtures
3. Use the pattern:
   ```typescript
   import { test, expect } from '@playwright/test';
   import { LoginPage } from '@pages/index';
   
   test.describe('Feature Name', () => {
     test('should do something', async ({ page }) => {
       // Test implementation
     });
   });
   ```

## Best Practices

1. **Use Page Objects**: Don't hardcode selectors in tests
2. **Use data-testid**: Add data-testid attributes to elements for stable selectors
3. **Clean State**: Each test should be independent
4. **Explicit Waits**: Use Playwright's built-in waiting mechanisms
5. **Descriptive Names**: Test names should clearly describe what they test

## CI/CD Integration

Tests are configured to run in CI with:
- JUnit reporting: `test-results/junit.xml`
- Screenshots on failure: `test-results/screenshots/`
- Videos on failure: `test-results/videos/`