# Business Rule Testing Guide

## Overview

This guide maps critical business rules to their test coverage, ensuring every important system behavior is properly validated. Business rules are the core logic that defines how the SaaS application operates and protects data integrity, security, and revenue.

## Business Rule Categories

### User Management Rules (CR-U/IR-U)

#### CR-U1: User Type Immutability (Weight: 10)
**Rule**: User type cannot be changed after creation  
**Risk**: Billing system corruption, permission bypass  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:424-436`

#### CR-U2: User Type Isolation (Weight: 10)
**Rule**: User types must have isolated associations  
**Risk**: Cross-contamination of billing and permissions  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:467-537`

#### CR-U3: Direct User Team Rules (Weight: 9)
**Rule**: Direct users must own teams they're associated with  
**Risk**: Invitation system bypass  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:439-464`

#### CR-U5: Direct User Team Creation (Weight: 8)
**Rule**: Only direct users can create teams  
**Risk**: Unauthorized team creation  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:86-130`

### Authentication & Authorization Rules (CR-A/IR-A)

#### CR-A1: Password Complexity (Weight: 9)
**Rule**: Passwords require uppercase, lowercase, number, special char, 8+ length  
**Risk**: Account compromise through weak passwords  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:328-381`

#### CR-A2: System Role Hierarchy (Weight: 7)
**Rule**: super_admin > site_admin > user role hierarchy  
**Risk**: Privilege escalation  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:638-660`

#### CR-A3: Self-Role Change Prevention (Weight: 9)
**Rule**: Users cannot change their own system role  
**Risk**: Unauthorized privilege escalation  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:617-636`

#### CR-A4: Status Enforcement (Weight: 8)
**Rule**: Only active users can sign in  
**Risk**: Unauthorized access by deactivated accounts  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:133-183`

### Team Management Rules (CR-T/IR-T)

#### CR-T1: Team Creation Authority (Weight: 8)
**Rule**: Only super admins and direct users can create teams  
**Risk**: Unauthorized team creation  
**Test Coverage**: ⚠️ Partial (controller test needed)  
**Test Location**: Service object tests needed

#### CR-T2: Team Member Limits (Weight: 8)
**Rule**: Teams cannot exceed plan member limits  
**Risk**: Revenue loss through limit bypass  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:581-615`

#### CR-T3: Team Admin Requirement (Weight: 8)
**Rule**: Teams must always have at least one admin  
**Risk**: Orphaned teams without management  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:555-579`

#### CR-T4: Team Billing Independence (Weight: 9)
**Rule**: Teams have separate Stripe subscriptions  
**Risk**: Revenue tracking errors  
**Test Coverage**: ❌ Missing  
**Action Required**: Add integration tests

### Invitation Rules (CR-I/IR-I)

#### CR-I1: Email Uniqueness (Weight: 10)
**Rule**: Cannot invite existing users  
**Risk**: Duplicate accounts, billing conflicts  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:383-422`

#### CR-I2: Invitation Expiration (Weight: 8)
**Rule**: Invitations expire after 7 days  
**Risk**: Security vulnerability  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/invitation_test.rb`

#### CR-I3: Polymorphic Type Safety (Weight: 9)
**Rule**: Invitations only for Team or EnterpriseGroup  
**Risk**: Data corruption  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/invitation_test.rb`

#### CR-I4: User Creation on Accept (Weight: 9)
**Rule**: Accepting creates user with correct type  
**Risk**: Wrong user permissions  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/invitation_test.rb`

### Security Rules (CR-S)

#### CR-S1: CSRF Protection (Weight: 9)
**Rule**: State-changing requests require CSRF token  
**Risk**: Request forgery attacks  
**Test Coverage**: ❌ Missing  
**Action Required**: Add controller tests

#### CR-S2: Mass Assignment Protection (Weight: 9)
**Rule**: Strong parameters on all controllers  
**Risk**: Privilege escalation  
**Test Coverage**: ❌ Missing  
**Action Required**: Add parameter tests

### Billing Rules (CR-B/IR-B)

#### CR-B1: Billing Isolation (Weight: 9)
**Rule**: Individual and team billing are separate  
**Risk**: Revenue attribution errors  
**Test Coverage**: ⚠️ Partial  
**Test Location**: Model tests exist, integration needed

#### CR-B2: Plan Feature Enforcement (Weight: 6)
**Rule**: Features match active plan  
**Risk**: Revenue loss  
**Test Coverage**: ❌ Missing  
**Action Required**: Add service tests

#### CR-B3: Plan Segmentation (Weight: 8)
**Rule**: Plans segmented by user type  
**Risk**: Wrong pricing applied  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/plan_test.rb`

### Data Integrity Rules (CR-D/IR-D)

#### CR-D1: Foreign Key Integrity (Weight: 8)
**Rule**: Referential integrity maintained  
**Risk**: Orphaned records  
**Test Coverage**: ❌ Missing  
**Action Required**: Add association tests

#### CR-D2: Email Normalization (Weight: 7)
**Rule**: Emails lowercase and trimmed  
**Risk**: Duplicate accounts  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb:304-325`

### Enterprise Rules (CR-E)

#### CR-E1: Enterprise Admin via Invitation (Weight: 8)
**Rule**: Enterprise admins assigned by invitation  
**Risk**: Circular dependency  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/enterprise_group_test.rb`

#### CR-E2: Enterprise User Isolation (Weight: 9)
**Rule**: Enterprise users isolated from teams  
**Risk**: Permission contamination  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/user_test.rb`

### Audit Rules (CR-AU)

#### CR-AU1: Critical Operation Logging (Weight: 9)
**Rule**: All critical operations logged  
**Risk**: No audit trail  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/admin_activity_log_test.rb`

#### CR-AU2: Immutable Audit Trail (Weight: 9)
**Rule**: Logs cannot be modified/deleted  
**Risk**: Tampered audit trail  
**Test Coverage**: ✅ Complete  
**Test Location**: `test/models/admin_activity_log_test.rb`

## Test Coverage Summary by Category

| Category | Total Rules | Covered | Missing | Coverage % |
|----------|-------------|---------|---------|------------|
| User Management | 5 | 5 | 0 | 100% |
| Authentication | 4 | 4 | 0 | 100% |
| Team Management | 4 | 3 | 1 | 75% |
| Invitations | 5 | 5 | 0 | 100% |
| Security | 2 | 0 | 2 | 0% |
| Billing | 3 | 1 | 2 | 33% |
| Data Integrity | 2 | 1 | 1 | 50% |
| Enterprise | 2 | 2 | 0 | 100% |
| Audit | 2 | 2 | 0 | 100% |
| **TOTAL** | **29** | **23** | **6** | **79.3%** |

## Critical Missing Tests

### Priority 1: Security (Immediate)
1. **CSRF Protection Tests**
   ```ruby
   # Test all state-changing actions require CSRF
   test "POST without CSRF token is rejected" do
     # Implementation needed
   end
   ```

2. **Mass Assignment Protection**
   ```ruby
   # Test strong parameters in all controllers
   test "unpermitted parameters are filtered" do
     # Implementation needed
   end
   ```

### Priority 2: Revenue Protection (1-2 weeks)
1. **Team Billing Independence**
   ```ruby
   # Test teams have separate Stripe customers
   test "team and individual billing are isolated" do
     # Implementation needed
   end
   ```

2. **Plan Feature Enforcement**
   ```ruby
   # Test features match subscription plan
   test "access denied when exceeding plan limits" do
     # Implementation needed
   end
   ```

### Priority 3: Data Integrity (2-4 weeks)
1. **Foreign Key Constraints**
   ```ruby
   # Test cascade and restrict rules
   test "cannot delete user with active team membership" do
     # Implementation needed
   end
   ```

## Writing Business Rule Tests

### Test Structure Template
```ruby
# Weight: [1-10] - [Rule ID]: [Description]
test "[business behavior description]" do
  # Arrange - Set up test data
  
  # Act - Perform the action
  
  # Assert - Verify business rule is enforced
  
  # Document - Why this matters for the business
end
```

### Best Practices

1. **Reference the Rule**: Always include rule ID in test
2. **Test the Behavior**: Focus on what, not how
3. **Document Business Impact**: Explain why it matters
4. **Use Descriptive Names**: Test name should explain the rule
5. **Test Edge Cases**: Especially for high-weight rules

### Example High-Quality Test
```ruby
# Weight: 10 - CR-U1: User type immutability
test "user type cannot be changed after creation to prevent billing system corruption" do
  # This protects against users switching between billing systems
  # which would corrupt revenue tracking and permissions
  
  direct_user = create(:user, user_type: 'direct')
  
  # Attempt to change to invited (team billing)
  direct_user.user_type = 'invited'
  assert_not direct_user.save
  assert_includes direct_user.errors[:user_type], "cannot be changed"
  
  # Verify database wasn't updated
  assert_equal 'direct', direct_user.reload.user_type
end
```

## Monitoring Business Rule Coverage

### Automated Checks
1. **Pre-commit Hook**: Verify no rules lost coverage
2. **CI Pipeline**: Block PRs reducing coverage
3. **Weekly Report**: Coverage trends by category
4. **Alerts**: Notify when coverage drops below target

### Manual Reviews
1. **Monthly**: Review new business rules
2. **Quarterly**: Re-evaluate rule weights
3. **Annually**: Full coverage audit

## Adding New Business Rules

When adding a new business rule:

1. **Document the Rule**
   - Add to this guide with unique ID
   - Assign weight based on impact
   - Describe the risk if violated

2. **Write the Test First**
   - TDD approach for business rules
   - Include rule reference in test
   - Cover edge cases

3. **Update Coverage Tracking**
   - Add to test mapping CSV
   - Update coverage metrics
   - Notify team of new rule

---

**Last Updated**: June 2025  
**Rule Count**: 29  
**Coverage**: 79.3%  
**Target**: 90% by Q3 2025