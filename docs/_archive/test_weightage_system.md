# Test Weightage System

## Overview

This document assigns specific weightage (1-10) to each test based on:
- Business rule criticality
- Security impact
- Data integrity risk
- Revenue protection
- User experience impact

## Weightage Scale

- **10**: Critical business rules that prevent system corruption
- **9**: Security-critical functionality
- **8**: Revenue-impacting features
- **7**: Data integrity and core functionality
- **6**: Important business logic
- **5**: Standard validations
- **4**: Helper methods with business value
- **3**: Simple validations and formatting
- **2**: Framework default behavior
- **1**: Trivial getters/setters

---

## User Model Tests

### Critical Tests (Weight 9-10)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| User type immutability | CR-U1 | 10 | Core system integrity - changing would break billing/permissions |
| User type isolation | CR-U2 | 10 | Prevents billing contamination between user types |
| Direct user team ownership | CR-U3 | 9 | Prevents invitation system bypass |
| Password complexity | CR-A1 | 9 | Security critical - prevents weak passwords |
| Email uniqueness | IR-U1 | 9 | Authentication integrity |
| Email conflicts with invitations | CR-I1 | 9 | Prevents duplicate accounts |
| System role self-change prevention | CR-A3 | 9 | Prevents privilege escalation |

### High Priority Tests (Weight 7-8)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Team member limits | CR-T2 | 8 | Revenue protection - prevents plan limit bypass |
| Team admin requirement | CR-T3 | 8 | Prevents orphaned teams |
| Email normalization | IR-U3 | 7 | Data consistency |
| Authentication status checks | IR-U2 | 7 | Access control |
| Team role transitions | CR-T3 | 7 | Team management integrity |
| User associations validations | Multiple | 7 | Ensures data relationships |

### Medium Priority Tests (Weight 5-6)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Field format validations | Standard | 6 | User input quality |
| Devise authentication methods | IR-A3 | 6 | Framework integration |
| Lock status methods | IR-A1 | 6 | Security feature |
| Scopes (active, direct_users, etc.) | Query | 5 | Data filtering |
| Association tests | Rails | 5 | Basic relationship verification |

### Low Priority Tests (Weight 1-4)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Role check helpers (team_admin?, etc.) | Helper | 4 | Simple boolean logic |
| full_name method | Display | 2 | String concatenation |
| Multiple enterprise role variations | Helper | 2 | Redundant boolean checks |
| can_create_team? variations | Helper | 3 | Simple logic with multiple tests |

---

## Team Model Tests

### Critical Tests (Weight 9-10)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Member limit enforcement | CR-T2 | 9 | Revenue protection |
| Admin presence validation | CR-T3 | 9 | Team integrity |
| Slug uniqueness | IR-T1 | 8 | URL routing integrity |

### High Priority Tests (Weight 7-8)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| User deletion prevention | IR-T2 | 8 | Data integrity |
| Slug generation algorithm | IR-T1 | 7 | URL creation logic |
| Cache invalidation | IR-T3 | 7 | Performance critical |
| Plan features mapping | IR-T4 | 7 | Feature access control |

### Medium Priority Tests (Weight 5-6)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Basic validations | Standard | 6 | Input validation |
| Associations | Rails | 5 | Relationship verification |
| Scopes | Query | 5 | Data filtering |

### Low Priority Tests (Weight 1-4)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Enum value checks | Framework | 2 | Rails default behavior |
| Default values | Rails | 2 | Framework defaults |
| Pay module inclusion | Gem | 1 | Library integration check |

---

## Invitation Model Tests

### Critical Tests (Weight 9-10)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Email not in users table | CR-I1 | 10 | Prevents duplicate accounts |
| Accept creates correct user type | CR-I4 | 9 | User creation integrity |
| Polymorphic type safety | CR-I3 | 9 | Data integrity |
| Expiration validation | CR-I2 | 8 | Security best practice |

### High Priority Tests (Weight 7-8)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Token uniqueness | IR-I1 | 8 | Security requirement |
| Email normalization | IR-I3 | 7 | Data consistency |
| Enterprise admin assignment | IR-I4 | 7 | Enterprise management |
| Accepted status immutability | IR-I2 | 7 | Data integrity |

### Medium Priority Tests (Weight 5-6)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Basic validations | Standard | 6 | Input validation |
| Scopes | Query | 5 | Data filtering |
| Helper methods | Display | 5 | Status checks |

---

## Plan Model Tests

### High Priority Tests (Weight 7-8)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Plan segmentation | CR-B3 | 8 | Billing separation |
| Member limit validation | CR-T2 | 8 | Team limits |
| Free plan detection | IR-B2 | 7 | Pricing logic |
| Enterprise contact sales | IR-B3 | 7 | Sales process |

### Medium Priority Tests (Weight 5-6)

| Test | Business Rule | Weight | Justification |
|------|---------------|--------|---------------|
| Feature checking | IR-B4 | 6 | Feature access |
| Price formatting | Display | 5 | User interface |
| Scopes | Query | 5 | Data filtering |

---

## Test Optimization Strategy

### Tests to Keep (Weight 7-10)
1. All critical business rule validations
2. Security-related tests
3. Revenue-impacting tests
4. Data integrity tests
5. Complex business logic

### Tests to Consolidate (Weight 4-6)
1. Similar validation tests into parameterized tests
2. Multiple scope tests into single comprehensive test
3. Helper method variations into edge case tests

### Tests to Remove (Weight 1-3)
1. Simple getter/setter tests
2. Framework default behavior tests
3. Redundant boolean method variations
4. Trivial string manipulation tests

---

## Example: Optimized Test Structure

```ruby
class UserOptimizedTest < ActiveSupport::TestCase
  # ========== CRITICAL TESTS (Weight 9-10) ==========
  
  # Weight: 10 - CR-U1: User type immutability
  test "user type cannot be changed after creation" do
    # Single comprehensive test instead of multiple variations
  end
  
  # Weight: 10 - CR-U2: User type isolation matrix
  test "user type associations are properly isolated" do
    # Test all combinations in one test with clear assertions
  end
  
  # ========== HIGH PRIORITY TESTS (Weight 7-8) ==========
  
  # Weight: 8 - CR-T2: Team member limits
  test "team member limits are enforced" do
    # Single test covering the critical path
  end
  
  # ========== MEDIUM PRIORITY TESTS (Weight 5-6) ==========
  
  # Weight: 6 - Standard validations
  test "field validations work correctly" do
    # Parameterized test for all field validations
  end
  
  # ========== LOW PRIORITY (Removed) ==========
  # Removed: 6 enterprise role method tests → kept 1 comprehensive test
  # Removed: 4 full_name variations → kept 1 edge case test
  # Removed: Simple getter tests
end
```

---

## Test Coverage Goals

### By Weight Category
- Weight 9-10: 100% coverage required
- Weight 7-8: 95% coverage required
- Weight 5-6: 85% coverage required
- Weight 3-4: Optional, focus on edge cases
- Weight 1-2: Remove unless documenting behavior

### Overall Strategy
- Total tests after optimization: ~95 (from 151)
- High-value tests (7+): 65% of total
- Focus on business rules, not implementation details
- Each test should prevent a real bug or business failure