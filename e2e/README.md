# Playwright E2E Testing

This directory contains end-to-end tests for the Rails SaaS application using Playwright.

## Directory Structure

```
e2e/
├── tests/                  # Test files organized by feature area
│   ├── auth/              # Authentication flows (login, logout, password reset)
│   ├── direct-users/      # Direct user specific features
│   ├── teams/             # Team management and collaboration
│   ├── enterprise/        # Enterprise organization features
│   ├── admin/             # Admin dashboard functionality
│   └── shared/            # Common flows used across user types
├── pages/                 # Page Object Model classes
├── fixtures/              # Test fixtures and helpers
├── utils/                 # Utility functions
└── README.md             # This file
```

## Running Tests

```bash
# Run all tests
npm run e2e

# Run tests in UI mode
npm run e2e:ui

# Debug tests
npm run e2e:debug

# Generate code with Playwright codegen
npm run e2e:codegen

# Show test report
npm run e2e:report
```

## Test Organization

Tests are organized by user type and feature area:

### Authentication (`tests/auth/`)
- Login/logout flows for all user types
- Password reset
- Email confirmation
- Account lockout

### Direct Users (`tests/direct-users/`)
- Registration with plan selection
- Dashboard navigation
- Profile management
- Billing and subscription management
- Team creation

### Teams (`tests/teams/`)
- Team creation by Super Admin
- Invitation flows
- Member management
- Role assignments
- Team billing

### Enterprise (`tests/enterprise/`)
- Enterprise group creation
- Admin assignment
- Member invitations
- Enterprise-specific features

### Admin (`tests/admin/`)
- Super Admin functionality
- Site Admin features
- User management
- Impersonation
- System settings

## Page Objects

Page objects follow a consistent pattern:

```typescript
export class LoginPage extends BasePage {
  async login(email: string, password: string) {
    await this.page.fill('[data-testid="email"]', email);
    await this.page.fill('[data-testid="password"]', password);
    await this.page.click('[data-testid="login-button"]');
  }
}
```

## Test Data Management

Test data is managed through fixtures:
- User fixtures for different user types
- Team and enterprise group fixtures
- Plan and subscription fixtures

## Best Practices

1. **Test Isolation**: Each test should be independent
2. **Data Cleanup**: Tests should clean up after themselves
3. **Explicit Waits**: Use Playwright's built-in waiting mechanisms
4. **Page Objects**: Use page objects for better maintainability
5. **Test IDs**: Use data-testid attributes for stable selectors

## Environment Variables

Configure test environment in `.env.test`:
- `BASE_URL`: Application URL for testing
- `TEST_DATABASE_URL`: Test database connection
- Test user credentials
- Stripe test keys
- Other service configurations

## CI/CD Integration

Tests are configured to run in CI with:
- Parallel execution
- Retry on failure
- JUnit reporting
- Screenshot/video on failure