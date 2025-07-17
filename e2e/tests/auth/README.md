# E2E Authentication Tests

This directory contains comprehensive end-to-end tests for the authentication system, with a focus on the login functionality.

## Test Files

### `login.spec.ts`
Basic login tests covering:
- Login form UI elements
- Successful login for all user types (direct, team, admin)
- Basic error handling
- Navigation links

### `login-comprehensive.spec.ts`
Advanced login tests including:
- **Security Tests**: CSRF protection, SQL injection prevention, XSS prevention, rate limiting, session fixation
- **Edge Cases**: Long emails, special characters, empty forms, browser back button, network failures
- **Performance Tests**: Login timing, slow network handling
- **Accessibility Tests**: Keyboard navigation, screen reader support, ARIA labels
- **Mobile Tests**: Responsive design, touch interactions
- **Multi-tab Tests**: Concurrent sessions handling
- **Visual Regression**: UI consistency checks

## Page Objects

### Enhanced `LoginPage.ts`
The login page object has been enhanced with:
- Data-testid selectors for stability
- Security validation methods
- Accessibility helpers
- Performance measurement
- Mobile-specific interactions
- Visual regression helpers

## Test Data

### Regular Users
- Super Admin: `super@example.com`
- Site Admin: `site@example.com`
- Direct User: `direct@example.com`
- Team Admin: `teamadmin@example.com`
- Team Member: `member@example.com`

### Edge Case Users
- Unconfirmed: `unconfirmed@example.com`
- Locked: `locked@example.com`
- Inactive: `inactive@example.com`
- Special chars: `user+test@example.com`
- Long password: `longpass@example.com`

## Helpers & Utilities

### `AuthHelpers` class
- Quick login bypassing UI
- CSRF token management
- Session validation
- Rate limit testing
- Authenticated context creation

### Test Helpers
- Network request monitoring
- Performance measurement
- Accessibility checking
- Retry logic for flaky tests
- Debug screenshots

## Running the Tests

```bash
# Run all auth tests
npm run test:e2e -- e2e/tests/auth/

# Run specific test file
npm run test:e2e -- e2e/tests/auth/login-comprehensive.spec.ts

# Run in headed mode for debugging
npm run test:e2e -- --headed e2e/tests/auth/login.spec.ts

# Run specific test
npm run test:e2e -- -g "should prevent SQL injection"
```

## Test Configuration

The tests are configured to:
- Run against `http://localhost:3001` (test server)
- Use test database with seeded data
- Take screenshots on failure
- Record videos for failed tests
- Support multiple browsers (Chrome, Firefox, Safari)
- Include mobile viewports

## Best Practices

1. **Use data-testid**: All interactive elements should have data-testid attributes
2. **Wait for network**: Use `waitForNetworkIdle` for consistent results
3. **Handle errors gracefully**: Tests should clean up even on failure
4. **Test accessibility**: Include keyboard and screen reader tests
5. **Mock external services**: Use API mocking for third-party services
6. **Performance matters**: Monitor and assert on performance metrics

## Troubleshooting

### Common Issues

1. **Rate limiting errors**: The app may rate limit after multiple failed attempts. Wait or use different IPs.
2. **Session conflicts**: Clear cookies between tests to avoid session issues.
3. **Timing issues**: Use proper wait conditions instead of fixed timeouts.
4. **Test data conflicts**: Ensure test data is properly cleaned up after each test.

### Debug Mode

To debug failing tests:
```bash
# Run with Playwright inspector
npm run test:e2e -- --debug

# Pause at specific point
await page.pause();
```

## Future Enhancements

- [ ] Add biometric authentication tests
- [ ] Test OAuth/SSO flows
- [ ] Add more visual regression tests
- [ ] Test password managers integration
- [ ] Add load testing for concurrent logins
- [ ] Test 2FA when implemented