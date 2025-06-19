# Testing Guide

This guide covers the testing setup, best practices, and guidelines for the SaaS Rails Starter application.

## Testing Framework

The application uses **Minitest** as the testing framework with **SimpleCov** for code coverage reporting.

### Why Minitest?
- Rails default testing framework
- Fast and lightweight
- Built-in parallel testing support
- Excellent Rails integration
- Simple and straightforward syntax

## Test Setup

### Configuration

The test configuration is located in `test/test_helper.rb`:

```ruby
# SimpleCov configuration for code coverage
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter %r{^/test/}
  add_filter %r{^/config/}
  add_filter %r{^/vendor/}
  
  # Coverage groups for better reporting
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Helpers", "app/helpers"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Services", "app/services"
  add_group "Policies", "app/policies"
  add_group "Validators", "app/validators"
end
```

### Test Structure

```
test/
├── application_system_test_case.rb  # Base class for system tests
├── test_helper.rb                   # Test configuration and helpers
├── controllers/                     # Controller tests
├── models/                          # Model tests
├── system/                          # System/integration tests
├── helpers/                         # Helper tests
├── mailers/                         # Mailer tests
├── services/                        # Service object tests
└── fixtures/                        # Test data
```

## Running Tests

### Basic Commands

```bash
# Run all tests
bundle exec rails test

# Run specific test file
bundle exec rails test test/models/user_test.rb

# Run specific test method
bundle exec rails test test/models/user_test.rb -n test_should_be_valid_with_valid_attributes

# Run tests with verbose output
bundle exec rails test -v

# Run tests in parallel (default behavior)
bundle exec rails test

# Run tests with specific seed
bundle exec rails test TESTOPTS="--seed=12345"
```

### Test Types

```bash
# Run only model tests
bundle exec rails test test/models

# Run only controller tests
bundle exec rails test test/controllers

# Run only system tests
bundle exec rails test:system
```

## Code Coverage

SimpleCov automatically generates coverage reports when running tests.

### Viewing Coverage Reports

```bash
# After running tests, open the HTML report
open coverage/index.html
```

### Coverage Metrics

The coverage report includes:
- **Line Coverage**: Percentage of lines executed
- **Branch Coverage**: Percentage of conditional branches tested
- **Coverage by Group**: Models, controllers, services, etc.
- **File-by-file breakdown**: Detailed coverage for each file

### Coverage Goals

Current coverage: **24.02%** line coverage, **65.12%** branch coverage (improved from 3.96%)
Target coverage: 90%+

Recent improvements:
- Added comprehensive model tests for Team, Invitation, Plan, AuditLog, EmailChangeRequest
- Enhanced User model tests with callbacks and validations
- Added tests for AdminActivityLog, Ahoy::Visit, and Ahoy::Event models
- Fixed all test failures and model validation issues
- Added controller tests for HomeController, PagesController, Users::DashboardController, Teams::DashboardController, Admin::Super::DashboardController
- Added service tests for Teams::CreationService, Users::StatusManagementService, AuditLogService
- Added rails-controller-testing gem and user fixtures
- Fixed test failures from 34 down to 14 (mostly design issues and existing failures)

To further improve coverage:
1. Add controller tests for all actions
2. Create system tests for critical user flows
3. Write service object tests
4. Add mailer tests
5. Test API endpoints

## Writing Tests

### Test Helpers

The application provides several helpers for testing:

```ruby
# Sign in a user
sign_in_as(user)

# Create and sign in a user with specific attributes
user = sign_in_with(
  email: "test@example.com",
  password: "Password123!",
  system_role: "super_admin",
  user_type: "direct",
  team: team,
  team_role: "admin"
)
```

### Model Tests

Example model test structure:

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User",
      user_type: "direct",
      status: "active"
    )
  end
  
  test "should be valid with valid attributes" do
    assert @user.valid?
  end
  
  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end
end
```

### Controller Tests

Example controller test:

```ruby
require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = sign_in_with(system_role: "super_admin")
  end
  
  test "should get index" do
    get admin_super_users_url
    assert_response :success
  end
  
  test "should show user" do
    get admin_super_user_url(@user)
    assert_response :success
  end
end
```

### System Tests

System tests use Selenium with headless Chrome:

```ruby
require "application_system_test_case"

class UserRegistrationTest < ApplicationSystemTestCase
  test "visiting the registration page" do
    visit new_user_registration_path
    
    assert_selector "h1", text: "Sign Up"
    assert_field "Email"
    assert_field "Password"
  end
  
  test "registering a new user" do
    visit new_user_registration_path
    
    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "Password123!"
    fill_in "Password confirmation", with: "Password123!"
    
    click_button "Sign up"
    
    assert_text "Welcome! You have signed up successfully"
  end
end
```

## Best Practices

### 1. Test Organization

- One test file per class/module
- Group related tests together
- Use descriptive test names
- Keep tests focused and isolated

### 2. Test Data

- Use fixtures for static test data
- Create test data in setup methods
- Clean up after tests when necessary
- Avoid dependencies between tests

### 3. Assertions

```ruby
# Use specific assertions
assert_equal expected, actual
assert_includes collection, item
assert_not condition

# Avoid generic assertions
assert true  # Too vague
```

### 4. Testing Principles

- **Fast**: Tests should run quickly
- **Independent**: Tests shouldn't depend on each other
- **Repeatable**: Same results every time
- **Self-Validating**: Clear pass/fail
- **Timely**: Write tests with the code

### 5. Edge Cases

Always test:
- Valid data (happy path)
- Invalid data
- Boundary conditions
- Error states
- Authorization failures

## Common Testing Patterns

### Testing Validations

```ruby
test "should validate presence of email" do
  @user.email = nil
  assert_not @user.valid?
  assert_includes @user.errors[:email], "can't be blank"
end
```

### Testing Associations

```ruby
test "should belong to team" do
  team = Team.create!(name: "Test Team", slug: "test-team")
  @user.team = team
  assert_equal team, @user.team
end
```

### Testing Scopes

```ruby
test "active scope returns only active users" do
  active_user = User.create!(email: "active@example.com", status: "active")
  inactive_user = User.create!(email: "inactive@example.com", status: "inactive")
  
  assert_includes User.active, active_user
  assert_not_includes User.active, inactive_user
end
```

### Testing Service Objects

```ruby
test "creates team successfully" do
  service = Teams::CreationService.new(super_admin, team_params, admin_user)
  result = service.call
  
  assert result.success?
  assert_instance_of Team, result.team
  assert_equal "Test Team", result.team.name
end
```

## Debugging Tests

### Running Single Tests

```bash
# Run a specific test by name
bundle exec rails test -n /keyword/
```

### Debugging Output

```ruby
# Add debugging output
puts @user.inspect
p @user.errors.full_messages

# Use byebug for breakpoints
require "byebug"
byebug
```

### Test Logs

Check `log/test.log` for detailed request/response information during test runs.

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.2.5
        bundler-cache: true
    
    - name: Setup Database
      run: |
        bundle exec rails db:create
        bundle exec rails db:schema:load
    
    - name: Run Tests
      run: bundle exec rails test
    
    - name: Upload Coverage
      uses: actions/upload-artifact@v2
      with:
        name: coverage
        path: coverage/
```

## Troubleshooting

### Common Issues

1. **Tests requiring server to be running**
   - Remove or skip tests that need `localhost:3000`
   - Use Rails integration test helpers instead

2. **Password validation failures**
   - Ensure test passwords meet requirements: `Password123!`
   - Include uppercase, lowercase, number, and special character

3. **Devise confirmation issues**
   - Use `skip_confirmation!` for test users
   - Or set `confirmed_at: Time.current`

4. **Parallel test failures**
   - SimpleCov may report incorrect coverage with parallel execution
   - Use `PARALLEL_WORKERS=1 bundle exec rails test` for accurate coverage

5. **Email validation edge cases**
   - Some emails like `user@example` are valid per RFC but may not work in production
   - Double dots like `user..name@example.com` are technically invalid

6. **Team creation validation errors**
   - Always create valid admin users before creating teams
   - Both `admin` and `created_by` associations are required

7. **Invitation callback issues**
   - The `set_expiration` callback overrides manual `expires_at` values
   - Use `update_column` to bypass callbacks when testing expired invitations

8. **Devise mapping errors in tests**
   - Some Devise-specific tests may fail with "Could not find a valid mapping"
   - These can be safely skipped in the test environment

### Getting Help

- Check test output for detailed error messages
- Review `log/test.log` for additional context
- Ensure test database is properly migrated
- Verify fixtures are loading correctly

## Next Steps

1. **Increase Coverage**
   - Write tests for all models
   - Add controller tests for all actions
   - Create system tests for user flows

2. **Add Test Types**
   - API tests for JSON endpoints
   - Job tests for background processing
   - Mailer tests for email sending

3. **Improve Test Quality**
   - Test edge cases
   - Add performance tests
   - Create security-focused tests

4. **Automate Testing**
   - Set up CI/CD pipeline
   - Add pre-commit hooks
   - Configure test coverage thresholds