# Authorization Guide

## Overview

The application uses Pundit for policy-based authorization, providing fine-grained access control that integrates seamlessly with our triple-track user system. This guide covers the authorization architecture, policy implementation, and best practices.

## Pundit Architecture

### Core Concepts

1. **Policies**: Ruby classes that define access rules
2. **Policy Scopes**: Filter collections based on permissions
3. **Authorization Checks**: Explicit permission verification
4. **Policy Helpers**: Reusable authorization logic

### Policy Structure

```ruby
app/policies/
├── application_policy.rb      # Base policy with common methods
├── user_policy.rb            # User management permissions
├── team_policy.rb            # Team access control
├── enterprise_group_policy.rb # Enterprise permissions
├── invitation_policy.rb       # Invitation management
├── plan_policy.rb            # Plan administration
└── admin/                    # Admin-specific policies
    ├── super_policy.rb       # Super admin permissions
    └── site_policy.rb        # Site admin permissions
```

## Base Policy Implementation

### ApplicationPolicy

```ruby
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Common helper methods
  def super_admin?
    user&.system_role == 'super_admin'
  end

  def site_admin?
    user&.system_role == 'site_admin'
  end

  def admin?
    super_admin? || site_admin?
  end

  def active_user?
    user&.status == 'active'
  end

  # Default permissions (deny all)
  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  # Base scope
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end
  end
end
```

## User Authorization Policies

### UserPolicy

```ruby
class UserPolicy < ApplicationPolicy
  # Viewing permissions
  def index?
    admin?
  end

  def show?
    # Admins can view anyone
    return true if admin?
    # Users can view themselves
    user == record
  end

  # Creation permissions
  def create?
    # Only through registration or invitation
    false
  end

  # Update permissions
  def update?
    # Super admins can update anyone
    return true if super_admin?
    
    # Site admins cannot update super admins
    return false if record.super_admin? && site_admin?
    
    # Site admins can update other users
    return true if site_admin?
    
    # Users can update themselves
    user == record
  end

  # Deletion permissions
  def destroy?
    # Super admins can delete users
    return true if super_admin?
    
    # Team admins can delete team members
    team_admin_can_delete?
  end

  # Special actions
  def impersonate?
    # Only admins can impersonate
    return false unless admin?
    
    # Cannot impersonate higher roles
    return false if record.super_admin? && !super_admin?
    
    # Cannot impersonate self
    user != record
  end

  def change_role?
    # Only super admins can change roles
    super_admin? && user != record
  end

  def set_status?
    # Admins can change user status
    admin? && user != record
  end

  # Scope for listing users
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        # Super admins see all users
        scope.all
      elsif user.site_admin?
        # Site admins see all except super admins
        scope.where.not(system_role: 'super_admin')
      elsif user.team_admin?
        # Team admins see their team members
        scope.where(team: user.team)
      else
        # Regular users see only themselves
        scope.where(id: user.id)
      end
    end
  end

  private

  def team_admin_can_delete?
    # Must be team admin
    return false unless user.team_admin?
    
    # Target must be invited user
    return false unless record.invited?
    
    # Must be same team
    user.team_id == record.team_id
  end
end
```

## Team Authorization Policies

### TeamPolicy

```ruby
class TeamPolicy < ApplicationPolicy
  def index?
    # Admins can list all teams
    admin?
  end

  def show?
    # Admins can view any team
    return true if admin?
    
    # Members can view their team
    user_belongs_to_team?
  end

  def create?
    # Only super admins can create teams
    super_admin?
  end

  def update?
    # Super admins can update any team
    return true if super_admin?
    
    # Team admins can update their team
    team_admin?
  end

  def destroy?
    # Only super admins can delete teams
    super_admin?
  end

  # Team-specific actions
  def manage_members?
    super_admin? || team_admin?
  end

  def manage_billing?
    # Super admins or the primary team admin
    super_admin? || (team_admin? && record.admin_id == user.id)
  end

  def manage_settings?
    super_admin? || team_admin?
  end

  def view_analytics?
    # Any team member can view analytics
    admin? || user_belongs_to_team?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        # Admins see all teams
        scope.all
      elsif user.invited?
        # Invited users see their team
        scope.where(id: user.team_id)
      elsif user.direct? && user.owns_team?
        # Direct users see teams they own
        scope.where(admin_id: user.id)
      else
        # Others see no teams
        scope.none
      end
    end
  end

  private

  def user_belongs_to_team?
    user.team_id == record.id
  end

  def team_admin?
    user.team_id == record.id && user.team_role == 'admin'
  end
end
```

## Enterprise Authorization Policies

### EnterpriseGroupPolicy

```ruby
class EnterpriseGroupPolicy < ApplicationPolicy
  def index?
    # Only super admins can list all groups
    super_admin?
  end

  def show?
    # Super admins or group members
    super_admin? || user_belongs_to_group?
  end

  def create?
    # Only super admins create enterprise groups
    super_admin?
  end

  def update?
    # Super admins or enterprise admins
    super_admin? || enterprise_admin?
  end

  def destroy?
    # Only super admins can delete groups
    super_admin?
  end

  # Enterprise-specific actions
  def manage_members?
    super_admin? || enterprise_admin?
  end

  def manage_billing?
    super_admin? || (enterprise_admin? && record.admin_id == user.id)
  end

  def view_reports?
    admin? || user_belongs_to_group?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.enterprise?
        scope.where(id: user.enterprise_group_id)
      else
        scope.none
      end
    end
  end

  private

  def user_belongs_to_group?
    user.enterprise_group_id == record.id
  end

  def enterprise_admin?
    user.enterprise_group_id == record.id && 
    user.enterprise_group_role == 'admin'
  end
end
```

## Invitation Authorization

### InvitationPolicy

```ruby
class InvitationPolicy < ApplicationPolicy
  def index?
    # Team/enterprise admins can list their invitations
    can_manage_invitations?
  end

  def show?
    # Admins or the invitee (via token)
    can_manage_invitations? || is_invitee?
  end

  def create?
    can_manage_invitations?
  end

  def resend?
    # Can only resend pending invitations
    can_manage_invitations? && record.pending?
  end

  def revoke?
    # Can only revoke pending invitations
    can_manage_invitations? && record.pending?
  end

  def accept?
    # Only the invitee can accept
    is_invitee? && record.pending? && !record.expired?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.team_admin?
        scope.where(team_id: user.team_id)
      elsif user.enterprise_admin?
        scope.where(
          invitable_type: 'EnterpriseGroup',
          invitable_id: user.enterprise_group_id
        )
      else
        scope.none
      end
    end
  end

  private

  def can_manage_invitations?
    case record.invitation_type
    when 'team'
      user.super_admin? || 
      (user.team_admin? && user.team_id == record.team_id)
    when 'enterprise'
      user.super_admin? || 
      (user.enterprise_admin? && 
       user.enterprise_group_id == record.invitable_id)
    else
      false
    end
  end

  def is_invitee?
    # Check if accessing via invitation token
    # This would be set in the controller
    @user.nil? && @record.token.present?
  end
end
```

## Controller Integration

### Base Controller Setup

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  # Callbacks
  before_action :authenticate_user!
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  
  # Exception handling
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    error_key = exception.query.to_s.remove('?')
    
    flash[:alert] = t(
      "#{policy_name}.#{error_key}", 
      scope: "pundit", 
      default: :default
    )
    
    redirect_back_or_to(root_path)
  end
end
```

### Resource Controllers

```ruby
class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  
  def index
    @users = policy_scope(User).page(params[:page])
  end
  
  def show
    authorize @user
  end
  
  def update
    authorize @user
    
    if @user.update(permitted_attributes(@user))
      redirect_to @user, notice: 'User updated.'
    else
      render :edit
    end
  end
  
  def destroy
    authorize @user
    @user.destroy
    redirect_to users_url
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
end
```

### Nested Resource Authorization

```ruby
class Teams::MembersController < Teams::BaseController
  before_action :set_member, only: [:show, :update, :destroy]
  
  def index
    authorize @team, :show?
    @members = policy_scope(@team.users)
  end
  
  def destroy
    authorize @team, :manage_members?
    authorize @member, :destroy?
    
    @member.destroy
    redirect_to team_members_path(@team)
  end
  
  private
  
  def set_member
    @member = @team.users.find(params[:id])
  end
end
```

## Advanced Authorization Patterns

### Custom Policy Methods

```ruby
class ProjectPolicy < ApplicationPolicy
  # Feature-specific permissions
  def export?
    return true if admin?
    user.team_admin? && record.team_id == user.team_id
  end
  
  def archive?
    update? && record.active?
  end
  
  def restore?
    update? && record.archived?
  end
  
  # Conditional permissions
  def publish?
    return false unless update?
    return true if admin?
    
    # Additional business logic
    record.complete? && !record.published?
  end
end
```

### Policy Composition

```ruby
class DocumentPolicy < ApplicationPolicy
  def show?
    # Delegate to parent project
    ProjectPolicy.new(user, record.project).show?
  end
  
  def update?
    # Must have project access AND document isn't locked
    ProjectPolicy.new(user, record.project).update? && 
    !record.locked?
  end
end
```

### Dynamic Permissions

```ruby
class FeaturePolicy < ApplicationPolicy
  def use?
    # Check if user's plan includes this feature
    return true if admin?
    
    if user.direct?
      user_has_feature?
    elsif user.invited?
      team_has_feature?
    elsif user.enterprise?
      enterprise_has_feature?
    end
  end
  
  private
  
  def user_has_feature?
    user.plan&.features&.include?(record.identifier)
  end
  
  def team_has_feature?
    user.team&.plan_features&.include?(record.identifier)
  end
  
  def enterprise_has_feature?
    user.enterprise_group&.plan&.features&.include?(record.identifier)
  end
end
```

## Testing Authorization

### Policy Tests

```ruby
require 'test_helper'

class TeamPolicyTest < ActiveSupport::TestCase
  def setup
    @super_admin = create(:user, :super_admin)
    @team_admin = create(:user, :team_admin)
    @team_member = create(:user, :team_member)
    @other_user = create(:user)
    @team = @team_admin.team
  end
  
  test "super admin can do everything" do
    policy = TeamPolicy.new(@super_admin, @team)
    
    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
    assert policy.manage_members?
    assert policy.manage_billing?
  end
  
  test "team admin can manage their team" do
    policy = TeamPolicy.new(@team_admin, @team)
    
    assert_not policy.index?
    assert policy.show?
    assert_not policy.create?
    assert policy.update?
    assert_not policy.destroy?
    assert policy.manage_members?
  end
  
  test "team member can only view" do
    policy = TeamPolicy.new(@team_member, @team)
    
    assert_not policy.index?
    assert policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.manage_members?
  end
  
  test "other users cannot access team" do
    policy = TeamPolicy.new(@other_user, @team)
    
    assert_not policy.show?
    assert_not policy.update?
  end
end
```

### Controller Authorization Tests

```ruby
class TeamsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  def setup
    @team_admin = create(:user, :team_admin)
    @team = @team_admin.team
    @other_user = create(:user)
  end
  
  test "team admin can update team" do
    sign_in @team_admin
    
    patch team_url(@team), params: { 
      team: { name: "New Name" } 
    }
    
    assert_redirected_to team_url(@team)
    assert_equal "New Name", @team.reload.name
  end
  
  test "other user cannot update team" do
    sign_in @other_user
    
    patch team_url(@team), params: { 
      team: { name: "New Name" } 
    }
    
    assert_redirected_to root_url
    assert_equal "You are not authorized", flash[:alert]
  end
  
  test "unauthenticated user redirected to login" do
    get team_url(@team)
    assert_redirected_to new_user_session_url
  end
end
```

## Best Practices

### 1. Explicit Authorization
```ruby
# Good - explicit authorization
def update
  @team = Team.find(params[:id])
  authorize @team
  # ...
end

# Bad - forgot authorization
def update
  @team = Team.find(params[:id])
  # ... no authorize call
end
```

### 2. Use Policy Scopes
```ruby
# Good - filtered by permissions
def index
  @teams = policy_scope(Team)
end

# Bad - shows all records
def index
  @teams = Team.all
end
```

### 3. Custom Error Messages
```ruby
# config/locales/pundit.en.yml
en:
  pundit:
    default: "You are not authorized to perform this action."
    team_policy:
      update?: "You cannot edit this team."
      destroy?: "You cannot delete this team."
    user_policy:
      impersonate?: "You cannot impersonate this user."
```

### 4. Permitted Attributes
```ruby
class UserPolicy < ApplicationPolicy
  def permitted_attributes
    if super_admin?
      [:email, :first_name, :last_name, :system_role, :status]
    elsif user == record
      [:email, :first_name, :last_name]
    else
      []
    end
  end
end

# In controller
def user_params
  params.require(:user).permit(policy(@user).permitted_attributes)
end
```

### 5. Headless Policies
```ruby
# For non-model authorization
class DashboardPolicy < Struct.new(:user, :dashboard)
  def show?
    user.present? && user.active?
  end
  
  def admin_stats?
    user.admin?
  end
end

# In controller
def show
  authorize :dashboard, :show?
end
```

## Security Considerations

### 1. Default Deny
- All permissions default to false
- Explicitly grant permissions
- Test both positive and negative cases

### 2. Scope Leakage
- Always use policy scopes for collections
- Never bypass authorization checks
- Verify scopes in tests

### 3. Role Hierarchy
- Respect role boundaries
- Prevent privilege escalation
- Audit role changes

### 4. Performance
- Cache policy checks when possible
- Optimize scope queries
- Use includes to prevent N+1

---

**Last Updated**: June 2025
**Related**: [Authentication](authentication.md) | [Security Best Practices](best-practices.md)