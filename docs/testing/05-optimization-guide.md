# Test Optimization Guide

## Overview

This guide provides practical strategies for optimizing test suites based on business value, reducing maintenance burden while improving test effectiveness.

## Optimization Principles

### 1. Business Value First
- Focus on tests that prevent real business failures
- Prioritize tests that protect revenue, security, and data integrity
- Remove tests that only verify implementation details

### 2. Weight-Based Prioritization
- Use the 1-10 scale consistently
- Keep all tests weight 7+
- Consolidate tests weight 4-6
- Remove tests weight 1-3

### 3. Quality Over Quantity
- One comprehensive test > multiple shallow tests
- Test behavior, not implementation
- Focus on edge cases for critical features

## Optimization Process

### Step 1: Audit Existing Tests

#### Identify Test Weight
```ruby
# For each test, ask:
# 1. What business rule does this protect?
# 2. What happens if this test is removed?
# 3. How much revenue/security risk is involved?
# 4. Could this be tested more efficiently?
```

#### Categorize Tests
| Weight | Action | Example |
|--------|--------|---------|
| 9-10 | Keep & enhance | Password security, billing isolation |
| 7-8 | Keep as-is | Data validation, access control |
| 5-6 | Consolidate | Multiple validations, scopes |
| 3-4 | Consider removing | Simple helpers, formatting |
| 1-2 | Remove | Getters, framework defaults |

### Step 2: Remove Low-Value Tests

#### Tests to Remove
1. **Simple Getters/Setters**
   ```ruby
   # Remove this:
   test "returns user full name" do
     user = User.new(first_name: "John", last_name: "Doe")
     assert_equal "John Doe", user.full_name
   end
   ```

2. **Framework Defaults**
   ```ruby
   # Remove this:
   test "has many associations" do
     assert User.new.respond_to?(:teams)
   end
   ```

3. **Redundant Validations**
   ```ruby
   # Instead of 5 presence tests, use 1:
   test "validates required fields" do
     user = User.new
     assert_not user.valid?
     assert_includes user.errors[:email], "can't be blank"
     assert_includes user.errors[:password], "can't be blank"
   end
   ```

### Step 3: Consolidate Medium-Value Tests

#### Pattern: Matrix Testing
```ruby
# Before: 6 separate tests
test "direct user cannot have team_role"
test "invited user must have team_role"
test "enterprise user cannot have team_role"
# ... 3 more similar tests

# After: 1 comprehensive test
test "user type associations follow isolation rules" do
  test_cases = [
    { type: 'direct', team_id: nil, enterprise_id: nil, valid: true },
    { type: 'invited', team_id: 1, enterprise_id: nil, valid: true },
    { type: 'enterprise', team_id: nil, enterprise_id: 1, valid: true },
    # Invalid combinations
    { type: 'direct', team_id: 1, enterprise_id: nil, valid: false },
    { type: 'invited', team_id: nil, enterprise_id: 1, valid: false }
  ]
  
  test_cases.each do |tc|
    user = build(:user, user_type: tc[:type], 
                       team_id: tc[:team_id], 
                       enterprise_group_id: tc[:enterprise_id])
    assert_equal tc[:valid], user.valid?, 
                "#{tc[:type]} user validation failed"
  end
end
```

#### Pattern: Parameterized Tests
```ruby
# Before: Multiple validation tests
test "password requires uppercase"
test "password requires lowercase"
test "password requires number"
test "password requires special char"

# After: One parameterized test
test "password enforces all complexity requirements" do
  invalid_passwords = {
    'short1!' => 'too short',
    'nouppercase1!' => 'uppercase letter',
    'NOLOWERCASE1!' => 'lowercase letter',
    'NoNumbers!' => 'number',
    'NoSpecial1' => 'special character'
  }
  
  user = build(:user)
  invalid_passwords.each do |password, missing|
    user.password = password
    assert_not user.valid?
    assert_match /must contain.*#{missing}/, 
                 user.errors[:password].to_s
  end
end
```

### Step 4: Enhance High-Value Tests

#### Add Business Context
```ruby
# Weight: 10 - CR-U1: User type immutability
test "user type cannot be changed to prevent billing corruption" do
  # Critical: Changing user type would break billing isolation
  # between individual and team subscriptions
  
  user = create(:user, user_type: 'direct')
  
  # Test all possible invalid transitions
  %w[invited enterprise].each do |new_type|
    user.user_type = new_type
    assert_not user.save
    assert_equal 'direct', user.reload.user_type
  end
end
```

#### Test Edge Cases
```ruby
# Weight: 9 - CR-T2: Team member limits
test "team member limits prevent revenue loss" do
  team = create(:team, plan: 'starter', max_members: 5)
  create_list(:user, 4, team: team)
  
  # At limit - 1
  assert team.can_add_members?
  
  # At limit
  create(:user, team: team)
  assert_not team.can_add_members?
  
  # Attempt to exceed
  user = build(:user, team: team)
  assert_not user.save
  assert_includes user.errors[:team], "has reached member limit"
end
```

## Common Optimization Patterns

### 1. Combine Related Assertions
```ruby
# Before: Multiple test methods
test "email is required"
test "email must be unique"
test "email is normalized"

# After: One comprehensive test
test "email validation and normalization" do
  # Test all email rules in one place
  user = build(:user, email: " DUPLICATE@EXAMPLE.COM ")
  create(:user, email: "duplicate@example.com")
  
  assert_not user.valid?
  assert_includes user.errors[:email], "has already been taken"
  
  user.email = " NEW@EXAMPLE.COM "
  assert user.save
  assert_equal "new@example.com", user.email
end
```

### 2. Use Shared Contexts
```ruby
# test_helper.rb
def assert_requires_authentication(path, method = :get)
  sign_out :user
  send(method, path)
  assert_redirected_to new_user_session_path
end

def assert_requires_admin(path, method = :get)
  sign_in create(:user) # regular user
  send(method, path)
  assert_response :forbidden
end

# In controller tests
test "admin endpoints require authentication and authorization" do
  admin_paths = [
    admin_super_dashboard_path,
    admin_super_users_path,
    admin_super_teams_path
  ]
  
  admin_paths.each do |path|
    assert_requires_authentication(path)
    assert_requires_admin(path)
  end
end
```

### 3. Test Workflows, Not Steps
```ruby
# Before: Testing each step
test "user can register"
test "user receives confirmation email"
test "user can confirm email"
test "user can sign in after confirmation"

# After: Test the complete flow
test "complete registration and confirmation flow" do
  # Test the entire user journey
  assert_difference 'User.count' do
    post user_registration_path, params: {
      user: { email: 'new@example.com', password: 'ValidPass1!' }
    }
  end
  
  user = User.last
  assert_not user.confirmed?
  assert_enqueued_email_with UserMailer, :confirmation_instructions
  
  # Simulate confirmation
  user.confirm
  
  # Verify can sign in
  post user_session_path, params: {
    user: { email: 'new@example.com', password: 'ValidPass1!' }
  }
  assert_redirected_to dashboard_path
end
```

## Performance Optimization

### 1. Minimize Database Operations
```ruby
# Slow: Creates records for each test
def setup
  @admin = create(:user, :admin)
  @team = create(:team)
  @members = create_list(:user, 5, team: @team)
end

# Fast: Use fixtures or factories sparingly
def setup
  @admin = users(:admin)
  @team = teams(:acme)
  # Only create what's needed for specific test
end
```

### 2. Use Transactional Tests
```ruby
# Ensure this is in test_helper.rb
class ActiveSupport::TestCase
  # Run tests in transactions
  self.use_transactional_tests = true
end
```

### 3. Parallelize Test Execution
```ruby
# config/application.rb
class Application < Rails::Application
  config.active_support.test_parallelization_workers = :number_of_processors
end
```

## Maintenance Best Practices

### 1. Document Test Purpose
```ruby
# Clear documentation
# Weight: 8 - CR-T3: Prevent orphaned teams
# This test ensures teams always have someone who can manage them
test "cannot remove last admin from team" do
  # ... test implementation
end
```

### 2. Group Related Tests
```ruby
class UserTest < ActiveSupport::TestCase
  # ========== CRITICAL TESTS (Weight 9-10) ==========
  
  test "user type immutability" do
    # ...
  end
  
  # ========== SECURITY TESTS (Weight 8-9) ==========
  
  test "password complexity requirements" do
    # ...
  end
  
  # ========== VALIDATION TESTS (Weight 5-6) ==========
  
  test "email format validation" do
    # ...
  end
end
```

### 3. Regular Reviews
- **Weekly**: Fix flaky tests
- **Monthly**: Review test execution times
- **Quarterly**: Re-evaluate test weights
- **Annually**: Major optimization pass

## Anti-Patterns to Avoid

### 1. Testing Implementation
```ruby
# Bad: Tests HOW it works
test "uses downcase method on email" do
  user = User.new(email: "TEST@EXAMPLE.COM")
  assert_equal "test@example.com", user.email.downcase
end

# Good: Tests WHAT it does
test "normalizes email to lowercase" do
  user = User.create(email: "TEST@EXAMPLE.COM")
  assert_equal "test@example.com", user.email
end
```

### 2. Brittle Assertions
```ruby
# Bad: Depends on exact wording
test "shows error message" do
  assert_equal "Email has already been taken", user.errors[:email].first
end

# Good: Tests the behavior
test "prevents duplicate emails" do
  create(:user, email: "test@example.com")
  duplicate = build(:user, email: "test@example.com")
  assert_not duplicate.valid?
  assert_not_empty duplicate.errors[:email]
end
```

### 3. Over-Mocking
```ruby
# Bad: Mocks the system under test
test "sends email" do
  mailer = mock()
  mailer.expects(:deliver_later)
  UserMailer.expects(:welcome).returns(mailer)
  # ...
end

# Good: Tests the actual behavior
test "sends welcome email" do
  assert_enqueued_email_with UserMailer, :welcome do
    create(:user)
  end
end
```

## Measuring Success

### Metrics to Track
1. **Test Execution Time**: Should decrease
2. **Test Flakiness**: Should approach zero
3. **Coverage of Critical Rules**: Should be 100%
4. **Average Test Weight**: Should increase
5. **Test-to-Code Ratio**: Should decrease

### Success Indicators
- ✅ All tests pass in < 5 minutes
- ✅ No flaky tests in CI
- ✅ 90%+ critical rule coverage
- ✅ Clear test organization
- ✅ Easy to add new tests

---

**Last Updated**: June 2025  
**Next Review**: September 2025  
**Goal**: Efficient, valuable test suite