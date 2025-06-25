# Testing Strategy

## Overview

This document outlines our comprehensive testing strategy for the SaaS Rails Starter Kit. Our approach prioritizes business value, security, and maintainability while optimizing for execution speed and developer productivity.

## Core Testing Principles

### 1. Business-First Testing
- **Focus on outcomes, not implementation**: Test what the system does, not how
- **Protect revenue streams**: Prioritize billing and subscription tests
- **Ensure data integrity**: Validate critical business rules at multiple levels
- **Security by default**: Every authentication/authorization path must be tested

### 2. Weighted Priority System
We use a 1-10 scale to prioritize tests based on business impact:

```
10 - Critical system integrity (data corruption prevention)
9  - Security and authentication (unauthorized access prevention)
8  - Revenue protection (billing, subscriptions, limits)
7  - Core business logic (user types, team management)
6  - Important features (invitations, settings)
5  - Standard validations (email format, required fields)
4  - Helper methods with business value
3  - Simple formatting and display logic
2  - Framework defaults (timestamps, basic CRUD)
1  - Trivial getters/setters
```

### 3. Test Pyramid Strategy

```
         /\
        /  \  System Tests (5%)
       /----\  - Critical user journeys
      /      \  - Security boundaries
     /--------\  Integration Tests (15%)
    /          \  - API endpoints
   /            \  - Controller flows
  /--------------\  Service Tests (30%)
 /                \  - Business operations
/                  \  - Complex workflows
/-------------------\  Model Tests (50%)
                        - Business rules
                        - Data integrity
                        - Validations
```

## Testing Categories

### 1. Model Tests (Foundation Layer)

**Purpose**: Validate business rules and data integrity at the lowest level

**Focus Areas**:
- Business rule enforcement
- Data validation
- Association integrity
- State transitions
- Scopes and queries

**Example High-Priority Tests**:
```ruby
# User type immutability (Weight: 10)
test "user type cannot be changed after creation"

# Password complexity (Weight: 9)
test "password requires uppercase, lowercase, number, and special char"

# Team member limits (Weight: 8)
test "team cannot exceed plan member limit"
```

### 2. Service Object Tests

**Purpose**: Validate complex business operations and workflows

**Focus Areas**:
- Multi-step operations
- Transaction integrity
- Error handling
- External service integration
- Business logic coordination

**Example High-Priority Tests**:
```ruby
# Team creation workflow (Weight: 9)
test "creates team with admin and billing setup"

# User status management (Weight: 8)
test "deactivating user invalidates all sessions"

# Invitation acceptance (Weight: 8)
test "accepting invitation creates correct user type"
```

### 3. Controller Tests

**Purpose**: Validate request handling, authentication, and authorization

**Focus Areas**:
- Authentication requirements
- Authorization rules
- Parameter filtering
- Response codes
- Security headers

**Example High-Priority Tests**:
```ruby
# Authorization enforcement (Weight: 9)
test "non-admin cannot access admin panel"

# CSRF protection (Weight: 9)
test "state-changing requests require valid token"

# Parameter filtering (Weight: 8)
test "mass assignment protection for sensitive attributes"
```

### 4. Integration Tests

**Purpose**: Validate complete request/response cycles

**Focus Areas**:
- API endpoint functionality
- Cross-component interaction
- Session management
- Cookie handling
- Multi-step workflows

**Example High-Priority Tests**:
```ruby
# Complete registration flow (Weight: 8)
test "user can register and access dashboard"

# Team invitation flow (Weight: 8)
test "admin can invite and user can join team"

# Billing update flow (Weight: 9)
test "user can update payment method"
```

### 5. System Tests

**Purpose**: Validate critical user journeys end-to-end

**Focus Areas**:
- Critical business workflows
- JavaScript interactions
- Multi-page flows
- External service integration
- Performance benchmarks

**Example High-Priority Tests**:
```ruby
# Complete purchase flow (Weight: 10)
test "user can sign up, select plan, and pay"

# Team management flow (Weight: 8)
test "admin can invite, manage, and remove members"

# Security boundary test (Weight: 9)
test "invited user cannot access individual features"
```

## Test Optimization Strategy

### 1. Identification Phase
- Assign weight to each test (1-10)
- Map tests to business rules
- Identify redundant coverage
- Find missing critical tests

### 2. Optimization Phase
- Remove tests with weight < 4
- Combine related low-weight tests
- Extract shared setup to helpers
- Focus on business outcomes

### 3. Enhancement Phase
- Add missing critical tests
- Improve test descriptions
- Add performance benchmarks
- Document skipped tests

### 4. Maintenance Phase
- Regular weight review (quarterly)
- Coverage analysis
- Performance monitoring
- Continuous improvement

## Coverage Goals

### By Test Weight
| Weight Range | Coverage Target | Rationale |
|--------------|----------------|-----------|
| 9-10 | 100% | Critical system integrity |
| 7-8 | 90% | Core business functionality |
| 5-6 | 70% | Important features |
| 3-4 | 40% | Nice-to-have coverage |
| 1-2 | 10% | Minimal coverage |

### By Component
| Component | Line Coverage | Branch Coverage |
|-----------|--------------|-----------------|
| Models | 90% | 85% |
| Services | 85% | 80% |
| Controllers | 80% | 75% |
| Helpers | 60% | 50% |
| Jobs | 80% | 70% |

## Test Writing Guidelines

### 1. Naming Conventions
```ruby
# Good: Describes the business rule
test "direct user cannot join team through invitation"

# Bad: Describes the implementation
test "returns false when user_type is direct"
```

### 2. Test Structure
```ruby
test "descriptive test name" do
  # Arrange - Set up test data
  user = create_test_user(type: 'direct')
  team = create_test_team
  
  # Act - Perform the action
  result = user.can_join_team?(team)
  
  # Assert - Verify the outcome
  assert_not result
  assert_includes user.errors[:base], "Direct users cannot join teams"
end
```

### 3. Test Data Management
- Use factories for complex objects (future)
- Use fixtures for reference data
- Create minimal valid objects
- Avoid interdependent data

### 4. Assertion Best Practices
- One logical assertion per test
- Use specific assertions (assert_equal vs assert)
- Include meaningful failure messages
- Test both positive and negative cases

## Performance Considerations

### 1. Test Execution Speed
- Target: Full suite under 5 minutes
- Parallelize test execution
- Use transactional fixtures
- Minimize database queries
- Cache expensive computations

### 2. Optimization Techniques
- Share expensive setup via fixtures
- Use stubs for external services
- Lazy load test data
- Skip view rendering in controller tests
- Use focused test runs during development

## Continuous Integration

### 1. CI Pipeline Stages
1. **Linting** - Code style checks
2. **Security** - Brakeman scanning
3. **Unit Tests** - Models and services
4. **Integration Tests** - Controllers and APIs
5. **System Tests** - Critical paths only
6. **Coverage Report** - Ensure no regression

### 2. Performance Benchmarks
- Unit tests: < 1 minute
- Integration tests: < 2 minutes
- System tests: < 2 minutes
- Total pipeline: < 5 minutes

## Test Maintenance

### 1. Regular Reviews
- Monthly: Fix flaky tests
- Quarterly: Re-evaluate test weights
- Semi-annually: Full optimization pass
- Annually: Strategy review

### 2. Documentation
- Document why tests are skipped
- Explain complex test setups
- Link tests to business rules
- Maintain test weight rationale

### 3. Metrics Tracking
- Test execution time
- Coverage trends
- Flaky test frequency
- Test-to-code ratio

## Anti-Patterns to Avoid

### 1. Testing Anti-Patterns
❌ Testing private methods directly
❌ Testing framework functionality
❌ Over-mocking (mock what you own)
❌ Testing implementation details
❌ Creating interdependent tests

### 2. Coverage Anti-Patterns
❌ Chasing 100% coverage everywhere
❌ Testing getters/setters
❌ Multiple tests for same behavior
❌ Testing generated code
❌ Low-value integration tests

### 3. Maintenance Anti-Patterns
❌ Commenting out failing tests
❌ Skipping tests without documentation
❌ Not fixing flaky tests
❌ Ignoring slow tests
❌ Not updating tests with code changes

## Success Metrics

### 1. Quality Metrics
- Zero production bugs from tested code
- 90%+ coverage of critical business rules
- < 1% flaky test rate
- All security paths tested

### 2. Velocity Metrics
- < 5 minute test suite
- < 10 minute CI pipeline
- Same-day test fixes
- Rapid test writing (< 2x code time)

### 3. Business Metrics
- Zero security breaches
- Zero data corruption
- Zero revenue loss from bugs
- High developer confidence

---

**Last Updated**: June 2025
**Next Review**: September 2025
**Owner**: Development Team Lead