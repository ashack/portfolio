# Business Logic Documentation

## Executive Summary

This document consolidates all critical business logic rules for the SaaS application. It serves as the authoritative source for understanding system constraints, user type behaviors, and security requirements. All tests should be evaluated against these documented rules.

> **Note**: For current test coverage statistics of these business rules, see [Business Logic Coverage Summary](../business_logic_coverage_summary.md)

## Table of Contents

1. [User Type System](#user-type-system)
2. [Authentication & Authorization](#authentication--authorization)
3. [Team Management](#team-management)
4. [Enterprise Groups](#enterprise-groups)
5. [Invitation System](#invitation-system)
6. [Billing & Subscriptions](#billing--subscriptions)
7. [Security Constraints](#security-constraints)
8. [Data Integrity Rules](#data-integrity-rules)

---

## User Type System

### Critical Rules (Must Never Be Violated)

#### CR-U1: User Type Immutability
- **Rule**: User type (`direct`, `invited`, `enterprise`) CANNOT be changed after creation
- **Implementation**: `user_type_cannot_be_changed` validation in User model
- **Database**: Check constraint ensures proper associations per user type
- **Risk**: HIGH - Changing user type would break billing, permissions, and data integrity

#### CR-U2: User Type Isolation
- **Rule**: Each user type has exclusive associations
  - Direct users: Can have personal billing (via Pay gem), can own teams, NO team_role unless owns_team, NO enterprise associations
  - Invited users: MUST have team association, MUST have team_role, CANNOT have personal billing, CANNOT own teams, NO enterprise associations
  - Enterprise users: MUST have enterprise association, MUST have enterprise_group_role, NO team associations, CANNOT own teams
- **Implementation**: `user_type_associations_valid` validation
- **Database**: `user_type_check` constraint
- **Risk**: HIGH - Cross-contamination would compromise billing and access control

#### CR-U3: Direct User Team Ownership
- **Rule**: Direct users can ONLY be associated with teams they own (`owns_team: true`)
- **Implementation**: `direct_user_team_ownership` validation
- **Risk**: HIGH - Allows direct users to bypass invitation system

### Important Rules

#### IR-U1: Email Uniqueness
- **Rule**: Email addresses must be unique across the system (case-insensitive)
- **Implementation**: Database unique index, model validation, `normalize_email` callback
- **Risk**: MEDIUM - Duplicate emails would break authentication

#### IR-U2: Status Management
- **Rule**: Only `active` users can sign in
- **States**: `active`, `inactive`, `locked`
- **Implementation**: `active_for_authentication?` method, `can_sign_in?` helper
- **Risk**: MEDIUM - Security and compliance requirement

#### IR-U3: Email Normalization
- **Rule**: All emails are normalized to lowercase and stripped of whitespace
- **Implementation**: `before_validation :normalize_email` callback
- **Risk**: MEDIUM - Prevents case-sensitive duplicates

---

## Authentication & Authorization

### Critical Rules

#### CR-A1: Password Complexity
- **Rule**: Passwords must be at least 8 characters with uppercase, lowercase, number, and special character
- **Implementation**: `password_complexity` validation
- **Risk**: HIGH - Weak passwords compromise account security

#### CR-A2: System Role Hierarchy
- **Rule**: System roles follow strict hierarchy and permissions
  - `super_admin`: Full system access, can create teams/enterprises
  - `site_admin`: Support access, read-only for billing
  - `user`: Standard user permissions
- **Implementation**: Pundit policies
- **Risk**: HIGH - Role confusion could grant unauthorized access

#### CR-A3: Self-Role Change Prevention
- **Rule**: Admins CANNOT change their own system role
- **Implementation**: `system_role_change_allowed` validation
- **Risk**: HIGH - Prevents privilege escalation

### Important Rules

#### IR-A1: Account Locking
- **Rule**: Accounts lock after 5 failed login attempts
- **Implementation**: Devise `:lockable` module, `needs_unlock?` and `lock_status` helpers
- **Risk**: MEDIUM - Brute force protection

#### IR-A2: Session Security
- **Rule**: Sessions expire after 30 days, HTTPS-only in production
- **Implementation**: Session store configuration
- **Risk**: MEDIUM - Session hijacking protection

#### IR-A3: Devise Security Modules
- **Rule**: Full Devise security enabled including confirmable and trackable
- **Modules**: `:database_authenticatable`, `:registerable`, `:recoverable`, `:rememberable`, `:validatable`, `:confirmable`, `:trackable`, `:lockable`
- **Risk**: MEDIUM - Comprehensive authentication security

---

## Team Management

### Critical Rules

#### CR-T1: Team Creation Authority
- **Rule**: Only Super Admins can create teams (except direct users creating their own)
- **Implementation**: `TeamPolicy#create?`, registration flow
- **Risk**: HIGH - Uncontrolled team creation affects billing

#### CR-T2: Member Limit Enforcement
- **Rule**: Teams cannot exceed their plan's member limit
- **Implementation**: `validate_team_member_limits` in User model, `can_add_members?` helper
- **Plan Limits**: Starter: 5, Pro: 15, Enterprise: 100
- **Risk**: HIGH - Billing integrity

#### CR-T3: Admin Requirement
- **Rule**: Every team MUST have at least one admin
- **Implementation**: `validate_team_role_transitions`, prevents last admin from becoming member
- **Risk**: HIGH - Orphaned teams cannot be managed

#### CR-T4: Team Billing Independence
- **Rule**: Teams have their own Stripe subscriptions separate from individual users
- **Implementation**: Team model includes `pay_customer`, separate `stripe_customer_id`
- **Risk**: HIGH - Revenue tracking and billing accuracy

### Important Rules

#### IR-T1: Slug Uniqueness
- **Rule**: Team slugs must be unique and URL-safe
- **Implementation**: `generate_slug` method, unique index, auto-increment on conflicts
- **Format**: Lowercase, alphanumeric with hyphens only, no leading/trailing hyphens
- **Risk**: MEDIUM - URL routing conflicts

#### IR-T2: User Deletion Prevention
- **Rule**: Teams with users cannot be deleted (restrict_with_error)
- **Implementation**: `dependent: :restrict_with_error` on users association
- **Risk**: MEDIUM - Data integrity

#### IR-T3: Team Caching
- **Rule**: Team slugs are cached for performance
- **Implementation**: `find_by_slug!` class method, `clear_caches` callback
- **Cache Duration**: 1 hour
- **Risk**: LOW - Performance optimization

#### IR-T4: Team Features by Plan
- **Rule**: Features are determined by team plan
- **Implementation**: `plan_features` method returns feature array
- **Features**:
  - Starter: `["team_dashboard", "collaboration", "email_support"]`
  - Pro: `["team_dashboard", "collaboration", "advanced_team_features", "priority_support"]`
  - Enterprise: `["team_dashboard", "collaboration", "advanced_team_features", "enterprise_features", "phone_support"]`
- **Risk**: MEDIUM - Feature access control

---

## Enterprise Groups

### Critical Rules

#### CR-E1: Admin Assignment via Invitation
- **Rule**: Enterprise admins MUST be assigned through invitation acceptance
- **Implementation**: `admin_id` nullable, set on invitation acceptance
- **Risk**: HIGH - Prevents circular dependency

#### CR-E2: Enterprise User Isolation
- **Rule**: Enterprise users CANNOT have team associations
- **Implementation**: Database constraints, model validations
- **Risk**: HIGH - Billing and access control

### Important Rules

#### IR-E1: Plan Requirement
- **Rule**: Enterprise groups MUST have an associated plan
- **Implementation**: `belongs_to :plan`, presence validation
- **Risk**: MEDIUM - Billing requirement

---

## Invitation System

### Critical Rules

#### CR-I1: New Email Only
- **Rule**: Invitations can ONLY be sent to emails NOT in users table
- **Implementation**: `email_not_in_users_table` validation
- **Risk**: HIGH - Prevents duplicate accounts

#### CR-I2: Invitation Expiration
- **Rule**: Invitations expire after 7 days
- **Implementation**: `expires_at` field, `not_expired` validation
- **Risk**: MEDIUM - Security best practice

#### CR-I3: Polymorphic Type Safety
- **Rule**: Team invitations require team_id, enterprise invitations require invitable
- **Implementation**: Conditional validations based on `invitation_type`, `set_invitable_from_team` callback
- **Risk**: HIGH - Data integrity

#### CR-I4: Invitation Acceptance Creates User
- **Rule**: Accepting invitation creates appropriate user type with proper associations
- **Implementation**: `accept!` method creates user in transaction
- **User Types Created**:
  - Team invitation → `invited` user with team/role
  - Enterprise invitation → `enterprise` user with enterprise_group/role
- **Risk**: HIGH - User creation integrity

### Important Rules

#### IR-I1: Token Uniqueness
- **Rule**: Invitation tokens must be cryptographically unique
- **Implementation**: `SecureRandom.urlsafe_base64(32)`
- **Risk**: MEDIUM - Security requirement

#### IR-I2: Accepted Invitation Immutability
- **Rule**: Accepted invitations cannot be revoked
- **Implementation**: UI logic, `accepted?` checks
- **Risk**: LOW - UX consideration

#### IR-I3: Email Normalization
- **Rule**: Invitation emails are normalized to lowercase and stripped
- **Implementation**: `normalize_email` callback
- **Risk**: MEDIUM - Prevents case-sensitive mismatches

#### IR-I4: Enterprise Admin Assignment
- **Rule**: Enterprise admin invitations update the enterprise group's admin on acceptance
- **Implementation**: Special handling in `accept!` method for enterprise admin invitations
- **Risk**: MEDIUM - Enterprise management integrity

---

## Billing & Subscriptions

### Critical Rules

#### CR-B1: Billing Separation
- **Rule**: Team billing and individual billing are completely separate
- **Implementation**: Pay gem with different billable models
- **Risk**: HIGH - Revenue integrity

#### CR-B2: Plan Enforcement
- **Rule**: Features and limits must match the active plan
- **Implementation**: `plan_features` methods, member limits
- **Risk**: HIGH - Revenue protection

#### CR-B3: Plan Segmentation
- **Rule**: Plans are strictly segmented by user type
- **Segments**: `individual`, `team`, `enterprise`
- **Implementation**: `plan_segment` enum with validation
- **Risk**: HIGH - Prevents wrong plan assignment

### Important Rules

#### IR-B1: Trial Period
- **Rule**: Starter teams get 14-day trial
- **Implementation**: `trial_ends_at` field
- **Risk**: MEDIUM - Business policy

#### IR-B2: Free Plan Support
- **Rule**: Plans with `amount_cents = 0` are free
- **Implementation**: `free?` method, `formatted_price` returns "Free"
- **Risk**: LOW - Pricing display

#### IR-B3: Enterprise Contact Sales
- **Rule**: Enterprise plans require sales contact (no self-service)
- **Implementation**: `contact_sales?` method, `available_for_signup` scope excludes enterprise
- **Risk**: MEDIUM - Sales process enforcement

#### IR-B4: Plan Features
- **Rule**: Plans have JSON array of feature identifiers
- **Implementation**: `has_feature?` method checks features array
- **Risk**: MEDIUM - Feature access control

---

## Security Constraints

### Critical Rules

#### CR-S1: CSRF Protection
- **Rule**: All state-changing requests must include CSRF token
- **Implementation**: Rails default, per-form tokens enabled
- **Risk**: HIGH - Request forgery protection

#### CR-S2: Mass Assignment Protection
- **Rule**: User-supplied parameters must be explicitly permitted
- **Implementation**: Strong parameters in all controllers
- **Risk**: HIGH - Privilege escalation

#### CR-S3: Rate Limiting
- **Rule**: Authentication endpoints must be rate-limited
- **Implementation**: Rack::Attack configuration
- **Risk**: HIGH - Brute force protection

---

## Data Integrity Rules

### Critical Rules

#### CR-D1: Foreign Key Integrity
- **Rule**: All associations must maintain referential integrity
- **Implementation**: Database foreign key constraints
- **Risk**: HIGH - Orphaned records

#### CR-D2: Email Normalization
- **Rule**: All emails stored as lowercase, trimmed
- **Implementation**: `normalize_email` callback in User and Invitation models
- **Risk**: MEDIUM - Prevents duplicate accounts

#### CR-D3: Team Integrity
- **Rule**: Teams must always have valid admin and created_by references
- **Implementation**: `belongs_to` validations, presence requirements
- **Risk**: HIGH - Orphaned teams cannot function

### Important Rules

#### IR-D1: Soft Delete Consideration
- **Rule**: User records should be soft-deleted to maintain audit trail
- **Implementation**: Currently hard delete - consider adding `deleted_at`
- **Risk**: MEDIUM - Compliance requirement

---

## Test Priority Matrix

Based on the above business logic, tests should be prioritized as follows:

### Priority 1 (Weight 9-10): Critical Business Rules
- User type immutability and isolation
- Authentication and password security
- Team creation authority
- Invitation email uniqueness
- Billing separation

### Priority 2 (Weight 6-8): Important Functionality
- Role transitions and permissions
- Team member limits
- Status management
- Foreign key constraints
- Rate limiting

### Priority 3 (Weight 3-5): Standard Validations
- Field format validations
- Length validations
- Enum value checks
- Scope functionality

### Priority 4 (Weight 1-2): Framework Behavior
- Simple getters/setters
- Rails default behavior
- Trivial string manipulation
- Redundant variations

---

## Business Logic Helper Methods

### User Model Helpers

#### Authentication & Status
- `can_sign_in?` - Returns true only for active users
- `active_for_authentication?` - Devise override checking both status and locks
- `needs_unlock?` - Checks if account needs unlocking
- `lock_status` - Returns human-readable lock status
- `inactive_message` - Maps status to Devise message keys

#### Role Checks
- `team_admin?` - True for invited users with admin role OR direct users who own a team
- `team_member?` - True for invited users with member role
- `enterprise_admin?` - True for enterprise users with admin role
- `enterprise_member?` - True for enterprise users with member role
- `can_create_team?` - True for direct users who don't already own a team

### Team Model Helpers

#### Member Management
- `member_count` - Current number of team members
- `can_add_members?` - Checks against plan limit
- `plan_features` - Returns array of available features

#### URL & Caching
- `to_param` - Returns cached slug for URLs
- `Team.find_by_slug!` - Cache-friendly lookup
- `clear_caches` - Clears all team-related caches

### Invitation Model Helpers

#### Status Checks
- `expired?` - True if past expiration date
- `accepted?` - True if invitation was accepted
- `pending?` - True if not yet accepted
- `team_invitation?` - True for team invitations
- `enterprise_invitation?` - True for enterprise invitations

#### Core Functionality
- `accept!` - Creates user and marks invitation as accepted (transactional)
- `to_param` - Returns token for URL generation

### Plan Model Helpers

#### Pricing & Features
- `free?` - True if amount_cents is 0
- `formatted_price` - Returns human-readable price
- `has_feature?` - Checks if plan includes specific feature
- `contact_sales?` - True for enterprise plans
- `segment_display_name` - Returns display name for admin UI
- `display_segment` - Returns user-friendly segment name

---

## Appendix: Quick Reference

### User Type Rules
```
Direct Users:
- Can own teams (owns_team: true)
- Have personal billing via Pay gem
- NO team_role unless owns_team
- NO enterprise associations
- Can create teams during registration

Invited Users:
- MUST have team association
- MUST have team_role (member/admin)
- NO personal billing
- CANNOT own teams
- NO enterprise associations
- Created via invitation only

Enterprise Users:
- MUST have enterprise_group association
- MUST have enterprise_group_role (member/admin)
- NO team associations
- CANNOT own teams
- Created via enterprise invitation only
```

### Permission Matrix
```
System Roles:
- Super Admin: Full system access, create teams/enterprises
- Site Admin: Read all, manage users, NO billing/creation access
- User: Standard permissions based on user type

Team Roles:
- Team Admin: Manage team members, billing, settings
- Team Member: Access team features only

Enterprise Roles:
- Enterprise Admin: Manage enterprise members, billing, settings
- Enterprise Member: Access enterprise features only
```

### Critical Constraints
```
1. User type CANNOT change after creation
2. Emails must be unique (case-insensitive)
3. Invitations only to NEW emails (not in users table)
4. Teams MUST have at least one admin
5. Direct users can't join teams via invitation (only create/own)
6. Teams cannot exceed plan member limits
7. All emails normalized to lowercase
8. Invitations expire after 7 days
9. Passwords require uppercase, lowercase, number, special char
10. Admins cannot change their own system role
```

### Billing Models
```
Individual Billing:
- Direct users only
- Personal Stripe subscription
- Managed via Pay gem on User model

Team Billing:
- Teams have own Stripe subscription
- Separate from individual billing
- Managed via Pay gem on Team model

Enterprise Billing:
- Enterprise groups have own billing
- Contact sales model
- Custom pricing and features
```