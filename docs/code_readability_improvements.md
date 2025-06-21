# Code Readability and Rails Best Practices Improvements

## Overview

This document outlines the planned improvements to enhance code readability and better utilize Rails DSL throughout the codebase. The focus is on maintaining human-readable code while following Ruby and Rails conventions.

## Current State Assessment

### Strengths
- **Excellent Rails DSL usage** in models with proper associations, enums, and scopes
- **RESTful controller design** with consistent before_actions and strong parameters
- **Well-structured service objects** with clear naming and single responsibility
- **Consistent authorization patterns** using Pundit policies

### Areas Needing Improvement
- Large, complex models (especially User model with 350+ lines)
- Magic numbers and strings scattered throughout the code
- Performance concerns with OpenStruct usage
- Business logic mixed into controllers
- Risk with Thread-local storage usage
- Polymorphic invitation complexity could use abstraction

## Improvement Tasks

### 1. Extract User Model Concerns (Priority: High)

The User model has grown too large and handles multiple responsibilities. Break it into focused concerns:

#### Proposed Concerns:
```ruby
# app/models/concerns/user/authenticatable.rb
module User::Authenticatable
  extend ActiveSupport::Concern
  
  included do
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable, 
           :confirmable, :trackable, :lockable
    
    # Password validation methods
    validate :password_complexity, if: :password_required?
  end
end

# app/models/concerns/user/team_membership.rb
module User::TeamMembership
  extend ActiveSupport::Concern
  
  included do
    belongs_to :team, optional: true
    enum :team_role, { member: 0, admin: 1 }
    
    # Team-related validations
    validates :team_id, absence: true, if: :direct?
    validates :team_role, presence: true, if: :invited?
  end
end

# app/models/concerns/user/enterprise_membership.rb
module User::EnterpriseMembership
  extend ActiveSupport::Concern
  
  included do
    belongs_to :enterprise_group, optional: true
    enum :enterprise_group_role, { member: 0, admin: 1 }
    
    # Enterprise-related validations
    validates :enterprise_group_id, presence: true, if: :enterprise?
    validates :enterprise_group_role, presence: true, if: :enterprise?
  end
end

# app/models/concerns/user/billing_customer.rb
module User::BillingCustomer
  extend ActiveSupport::Concern
  
  included do
    pay_customer
    belongs_to :plan, optional: true
    
    # Billing-related methods
  end
end
```

### 2. Create Constants Module (Priority: High)

Replace magic numbers and strings with named constants:

```ruby
# app/models/concerns/app_constants.rb
module AppConstants
  # Time periods
  TRIAL_PERIOD = 14.days
  INVITATION_EXPIRY = 7.days
  ACTIVITY_TIMEOUT = 7.days
  
  # Team member limits
  TEAM_MEMBER_LIMITS = {
    starter: 5,
    pro: 15,
    enterprise: 100
  }.freeze
  
  # Enterprise member limits
  ENTERPRISE_MEMBER_LIMITS = {
    small: 50,
    medium: 200,
    large: 1000,
    unlimited: nil
  }.freeze
  
  # Plan features
  PLAN_FEATURES = {
    # Individual plans
    individual_free: ['basic_dashboard', 'email_support'],
    individual_pro: ['basic_dashboard', 'advanced_features', 'priority_support'],
    individual_premium: ['all_features', 'phone_support'],
    
    # Team plans
    team_starter: ['team_dashboard', 'collaboration', 'email_support'],
    team_pro: ['team_dashboard', 'collaboration', 'advanced_team_features', 'priority_support'],
    team_enterprise: ['all_team_features', 'phone_support', 'custom_integrations'],
    
    # Enterprise plans
    enterprise_small: ['enterprise_dashboard', 'sso', 'dedicated_support'],
    enterprise_medium: ['enterprise_dashboard', 'sso', 'api_access', 'dedicated_support'],
    enterprise_large: ['all_features', 'white_label', 'custom_development']
  }.freeze
  
  # Password requirements
  PASSWORD_MIN_LENGTH = 12
  PASSWORD_REQUIREMENTS = {
    uppercase: /[A-Z]/,
    lowercase: /[a-z]/,
    digit: /\d/,
    special: /[!@#$%^&*(),.?":{}|<>]/
  }.freeze
end
```

### 3. Replace OpenStruct with Result Objects (Priority: Medium)

Create a proper Result class for service objects:

```ruby
# app/models/service_result.rb
class ServiceResult
  attr_reader :data, :errors, :message
  
  def initialize(success:, data: nil, errors: [], message: nil)
    @success = success
    @data = data
    @errors = Array(errors)
    @message = message
  end
  
  def success?
    @success
  end
  
  def failure?
    !@success
  end
  
  class << self
    def success(data = nil, message: nil)
      new(success: true, data: data, message: message)
    end
    
    def failure(errors, message: nil)
      new(success: false, errors: errors, message: message)
    end
  end
end
```

### 4. Remove Thread-local Storage (Priority: High)

Replace risky Thread.current usage with explicit parameter passing:

```ruby
# Instead of:
Thread.current[:current_admin_user] = admin_user

# Use explicit context:
class ValidationContext
  attr_reader :admin_user, :request
  
  def initialize(admin_user: nil, request: nil)
    @admin_user = admin_user
    @request = request
  end
end

# Pass context explicitly to methods that need it
user.update_with_context(params, context: ValidationContext.new(admin_user: current_user))
```

### 5. Extract Controller Business Logic (Priority: Medium)

Move complex logic from controllers to services:

```ruby
# app/services/users/parameter_validation_service.rb
class Users::ParameterValidationService
  def initialize(user, params, current_admin)
    @user = user
    @params = params
    @current_admin = current_admin
  end
  
  def call
    validate_user_type_change
    validate_system_role_change
    validate_plan_change
    
    ServiceResult.success(@params)
  rescue ValidationError => e
    ServiceResult.failure(e.message)
  end
  
  private
  
  def validate_user_type_change
    if @params[:user_type].present?
      raise ValidationError, "User type cannot be changed - core business rule"
    end
  end
end
```

### 6. Create Query Objects (Priority: Medium)

Extract complex queries into dedicated objects:

```ruby
# app/queries/users/active_team_members_query.rb
class Users::ActiveTeamMembersQuery
  def initialize(team:, includes: [])
    @team = team
    @includes = includes
  end
  
  def call
    User.active
        .where(team: @team)
        .includes(@includes)
        .order(:last_name, :first_name)
  end
end

# Usage in controller:
@members = Users::ActiveTeamMembersQuery.new(
  team: @team,
  includes: [:plan, :pay_customers]
).call
```

### 7. Add Presenters/Decorators (Priority: Low)

Create presenters for complex view logic:

```ruby
# app/presenters/user_presenter.rb
class UserPresenter < SimpleDelegator
  def display_name
    full_name.presence || email
  end
  
  def status_badge_class
    case status
    when 'active' then 'bg-green-100 text-green-800'
    when 'inactive' then 'bg-gray-100 text-gray-800'
    when 'locked' then 'bg-red-100 text-red-800'
    end
  end
  
  def role_description
    if super_admin?
      "Super Administrator"
    elsif site_admin?
      "Site Administrator"
    elsif team_admin?
      "Team Administrator"
    else
      "Member"
    end
  end
end
```

### 8. Refactor Long Methods (Priority: Medium)

Break down complex methods into smaller, focused ones:

```ruby
# Before:
def complex_validation_method
  # 50+ lines of validation logic
end

# After:
def complex_validation_method
  validate_basic_requirements
  validate_business_rules
  validate_relationships
end

private

def validate_basic_requirements
  # 10-15 lines focused on one aspect
end

def validate_business_rules
  # 10-15 lines focused on business logic
end

def validate_relationships
  # 10-15 lines focused on associations
end
```

### 9. Standardize Error Handling (Priority: Medium)

Implement consistent error handling:

```ruby
# app/services/application_service.rb
class ApplicationService
  class ServiceError < StandardError; end
  class ValidationError < ServiceError; end
  class AuthorizationError < ServiceError; end
  
  protected
  
  def handle_errors
    yield
  rescue ActiveRecord::RecordInvalid => e
    ServiceResult.failure(e.record.errors.full_messages)
  rescue ValidationError => e
    ServiceResult.failure(e.message)
  rescue StandardError => e
    Rails.logger.error "Service error: #{e.message}"
    ServiceResult.failure("An unexpected error occurred")
  end
end
```

### 10. Add Missing Indexes (Priority: High)

Add database indexes for better performance:

```ruby
class AddMissingIndexes < ActiveRecord::Migration[7.1]
  def change
    # Foreign key indexes
    add_index :users, :team_id
    add_index :users, :plan_id
    add_index :users, :enterprise_group_id
    add_index :teams, :admin_id
    add_index :teams, :created_by_id
    
    # Query optimization indexes
    add_index :users, [:status, :user_type]
    add_index :users, :last_activity_at
    add_index :teams, [:status, :created_at]
    add_index :invitations, [:team_id, :accepted_at]
  end
end
```

## Implementation Guidelines

### Phase 1 (Week 1-2)
- Extract User model concerns
- Create constants module
- Add missing database indexes

### Phase 2 (Week 3-4)
- Replace OpenStruct with Result objects
- Remove Thread-local storage
- Standardize error handling

### Phase 3 (Week 5-6)
- Extract controller business logic
- Create query objects
- Refactor long methods

### Phase 4 (Week 7-8)
- Add presenters/decorators
- Final review and testing

## Testing Considerations

Each refactoring should:
1. Maintain 100% backward compatibility
2. Include comprehensive test coverage
3. Be deployed incrementally
4. Include performance benchmarks where relevant

## Success Metrics

- Reduce User model to under 100 lines
- Eliminate all magic numbers/strings
- Achieve consistent error handling across all services
- Improve query performance by 20%+
- Maintain or improve test coverage

## References

- [Rails Best Practices Guide](https://rails-bestpractices.com/)
- [Ruby Style Guide](https://rubystyle.guide/)
- [Refactoring Ruby Code](https://refactoring.guru/catalog)