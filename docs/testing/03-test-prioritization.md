# Test Prioritization Guide

## Overview

This guide implements a weighted priority system for tests based on business impact, security requirements, and revenue protection. We use a 1-10 scale to prioritize which tests to keep, consolidate, or remove.

## Weightage Scale

Tests are assigned weights from 1-10 based on their business criticality:

| Weight | Category | Description | Example |
|--------|----------|-------------|---------| 
| **10** | Critical business rules | Prevent system corruption | User type immutability |
| **9** | Security-critical | Authentication & authorization | Password complexity, Email uniqueness |
| **8** | Revenue-impacting | Billing, subscriptions, limits | Team member limits, Plan enforcement |
| **7** | Data integrity | Core functionality | Email normalization, Cache invalidation |
| **6** | Important logic | Business workflows | Field validations, Scopes |
| **5** | Standard validations | Basic checks | Required fields, Format validations |
| **4** | Helper methods | Business value utilities | Status checks, Display helpers |
| **3** | Simple validations | Basic formatting | String manipulation |
| **2** | Framework defaults | Rails behavior | Timestamps, Enums |
| **1** | Trivial | Getters/setters | Attribute readers |

## Test Optimization Strategy

### Identification Phase
1. Assign weight to each test (1-10)
2. Map tests to business rules
3. Identify redundant coverage
4. Find missing critical tests

### Optimization Actions

#### Tests to Keep (Weight 7-10)
- All critical business rule validations
- Security-related tests
- Revenue-impacting tests
- Data integrity tests
- Complex business logic

#### Tests to Consolidate (Weight 4-6)
- Similar validation tests into parameterized tests
- Multiple scope tests into single comprehensive test
- Helper method variations into edge case tests

#### Tests to Remove (Weight 1-3)
- Simple getter/setter tests
- Framework default behavior tests
- Redundant boolean method variations
- Trivial string manipulation tests

## Model Test Prioritization

### User Model Tests

#### Critical Tests (Weight 9-10)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| User type immutability | CR-U1 | 10 | Core system integrity - changing would break billing/permissions |
| User type isolation | CR-U2 | 10 | Prevents billing contamination between user types |
| Direct user team ownership | CR-U3 | 9 | Prevents invitation system bypass |
| Password complexity | CR-A1 | 9 | Security critical - prevents weak passwords |
| Email uniqueness | IR-U1 | 9 | Authentication integrity |
| Email conflicts with invitations | CR-I1 | 9 | Prevents duplicate accounts |
| System role self-change prevention | CR-A3 | 9 | Prevents privilege escalation |

#### High Priority Tests (Weight 7-8)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Team member limits | CR-T2 | 8 | Revenue protection - prevents plan limit bypass |
| Team admin requirement | CR-T3 | 8 | Prevents orphaned teams |
| Email normalization | IR-U3 | 7 | Data consistency |
| Authentication status checks | IR-U2 | 7 | Access control |
| Team role transitions | CR-T3 | 7 | Team management integrity |
| User associations validations | Multiple | 7 | Ensures data relationships |

#### Medium Priority Tests (Weight 5-6)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Field format validations | Standard | 6 | User input quality |
| Devise authentication methods | IR-A3 | 6 | Framework integration |
| Lock status methods | IR-A1 | 6 | Security feature |
| Scopes (active, direct_users, etc.) | Query | 5 | Data filtering |
| Association tests | Rails | 5 | Basic relationship verification |

#### Low Priority Tests (Weight 1-4)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Role check helpers (team_admin?, etc.) | Helper | 4 | Simple boolean logic |
| full_name method | Display | 2 | String concatenation |
| Multiple enterprise role variations | Helper | 2 | Redundant boolean checks |
| can_create_team? variations | Helper | 3 | Simple logic with multiple tests |

### Team Model Tests

#### Critical Tests (Weight 9-10)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Member limit enforcement | CR-T2 | 9 | Revenue protection |
| Admin presence validation | CR-T3 | 9 | Team integrity |
| Slug uniqueness | IR-T1 | 8 | URL routing integrity |

#### High Priority Tests (Weight 7-8)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| User deletion prevention | IR-T2 | 8 | Data integrity |
| Slug generation algorithm | IR-T1 | 7 | URL creation logic |
| Cache invalidation | IR-T3 | 7 | Performance critical |
| Plan features mapping | IR-T4 | 7 | Feature access control |

### Invitation Model Tests

#### Critical Tests (Weight 9-10)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Email not in users table | CR-I1 | 10 | Prevents duplicate accounts |
| Accept creates correct user type | CR-I4 | 9 | User creation integrity |
| Polymorphic type safety | CR-I3 | 9 | Data integrity |
| Expiration validation | CR-I2 | 8 | Security best practice |

#### High Priority Tests (Weight 7-8)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Token uniqueness | IR-I1 | 8 | Security requirement |
| Email normalization | IR-I3 | 7 | Data consistency |
| Enterprise admin assignment | IR-I4 | 7 | Enterprise management |
| Accepted status immutability | IR-I2 | 7 | Data integrity |

## Detailed Test-by-Test Optimization

### UserComprehensiveTest Optimization

**Before**: 838 lines, 53 tests  
**After**: ~500 lines, 29 tests

#### Test Consolidation Plan

| Line | Test Description | Weight | Action | Rationale |
|------|-----------------|--------|--------|-----------|
| 27-59 | enterprise_admin? variations | 2 | Consolidate to 1 test | Multiple tests for simple boolean |
| 61-83 | enterprise_member? variations | 2 | Consolidate to 1 test | Redundant coverage |
| 86-130 | can_create_team? variations | 2-3 | Keep 1 comprehensive test | Test all cases in matrix |
| 133-183 | active_for_authentication? | 7 | Consolidate to 1 test | Test all states together |
| 185-223 | inactive_message variations | 4 | Consolidate to 1 test | Simple string returns |
| 224-252 | needs_unlock? variations | 6 | Consolidate to 2 tests | Keep security paths |
| 264-302 | lock_status variations | 2-3 | Keep 1 test | Display logic only |
| 328-381 | password validations | 9 | Consolidate to 1 test | Test all rules together |
| 424-436 | user type immutability | 10 | Keep as-is | Critical test |
| 439-464 | direct user team rules | 9 | Consolidate to 1 test | Related validations |
| 467-536 | user type associations | 10 | Keep all | Critical isolation tests |
| 791-838 | full_name variations | 1-2 | Keep 1 edge case test | Trivial string logic |

### TeamComprehensiveTest Optimization  

**Before**: 579 lines, 41 tests  
**After**: ~350 lines, 27 tests

#### Test Consolidation Plan

| Line | Test Description | Weight | Action | Rationale |
|------|-----------------|--------|--------|-----------|
| 21-89 | Cache management | 6-7 | Keep all | Performance critical |
| 148-164 | plan_features variations | 7 | Consolidate to 1 test | Test all plans together |
| 167-253 | Slug generation | 6-8 | Keep critical ones | Core functionality |
| 351-371 | Name validations | 5 | Consolidate to 1 test | Standard validations |
| 432-435 | belongs_to associations | 4 | Consolidate with other associations | Rails defaults |
| 521-541 | Enum tests | 2 | Remove | Framework behavior |
| 544-579 | Default value tests | 1-3 | Keep only max_members | Business relevant default |

## Implementation Priority

### Phase 1: Remove Low-Value Tests (Weight 1-2)
1. Remove all tests with weight 1-2
2. Expected reduction: ~48 tests
3. Focus: Framework defaults, trivial getters

### Phase 2: Consolidate Medium Tests (Weight 3-6)  
1. Combine related tests into comprehensive tests
2. Use parameterized tests where appropriate
3. Expected reduction: ~30 tests

### Phase 3: Enhance High-Value Tests (Weight 7-10)
1. Ensure comprehensive coverage
2. Add missing edge cases
3. Improve test descriptions with business rule references

### Phase 4: Add Missing Critical Tests
1. Review business rules without tests
2. Add tests for uncovered critical paths
3. Focus on security and revenue protection

## Coverage Goals

### By Weight Category
| Weight Range | Coverage Target | Rationale |
|--------------|-----------------|-----------|
| 9-10 | 100% | Critical system integrity |
| 7-8 | 95% | Core business functionality |
| 5-6 | 85% | Important features |
| 3-4 | 40% | Nice-to-have coverage |
| 1-2 | 10% | Minimal coverage |

### Overall Targets
- Total tests after optimization: ~95 (from 151)
- High-value tests (7+): 65% of total
- Line reduction: 45% fewer lines
- Execution time: 50% faster

## Example Optimized Test Structure

```ruby
class UserOptimizedTest < ActiveSupport::TestCase
  # ========== CRITICAL TESTS (Weight 9-10) ==========
  
  # Weight: 10 - CR-U1: User type immutability
  test "user type cannot be changed after creation" do
    user = create_test_user(user_type: 'direct')
    original_type = user.user_type
    
    # Test all invalid transitions
    ['invited', 'enterprise'].each do |new_type|
      user.user_type = new_type
      assert_not user.save
      assert_equal original_type, user.reload.user_type
    end
  end
  
  # Weight: 10 - CR-U2: User type isolation matrix
  test "user type associations are properly isolated" do
    # Test all combinations in one comprehensive test
    direct_user = create_test_user(user_type: 'direct')
    invited_user = create_test_user(user_type: 'invited', team: team)
    enterprise_user = create_test_user(user_type: 'enterprise', enterprise_group: group)
    
    # Direct users: no team/enterprise associations
    assert_nil direct_user.team_id
    assert_nil direct_user.enterprise_group_id
    
    # Invited users: team but no enterprise
    assert_not_nil invited_user.team_id
    assert_nil invited_user.enterprise_group_id
    
    # Enterprise users: enterprise but no team
    assert_nil enterprise_user.team_id
    assert_not_nil enterprise_user.enterprise_group_id
  end
  
  # Weight: 9 - CR-A1: Password complexity matrix
  test "password enforces all security requirements" do
    user = build(:user)
    
    invalid_passwords = [
      ['short1!', 'too short'],
      ['lowercase1!', 'missing uppercase'],
      ['UPPERCASE1!', 'missing lowercase'],
      ['NoNumbers!', 'missing number'],
      ['NoSpecial1', 'missing special character']
    ]
    
    invalid_passwords.each do |password, reason|
      user.password = password
      assert_not user.valid?
      assert_includes user.errors[:password].to_s, reason
    end
    
    # Valid password passes all checks
    user.password = 'ValidPass1!'
    assert user.valid?
  end
end
```

## Maintenance Schedule

### Monthly
- Review and fix flaky tests
- Update test weights based on incidents
- Remove newly redundant tests

### Quarterly  
- Full test weight re-evaluation
- Coverage analysis
- Performance benchmarking

### Annually
- Complete optimization pass
- Strategy review
- Update business rule mappings

---

**Last Updated**: June 2025  
**Next Review**: September 2025  
**Owner**: Development Team Lead