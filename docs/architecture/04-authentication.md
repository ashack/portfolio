# Authentication & Authorization Architecture

## Overview

The application implements a comprehensive security architecture using Devise for authentication and Pundit for authorization. This dual-layer approach provides flexible, maintainable, and secure access control throughout the system.

## Authentication Architecture (Devise)

### Devise Configuration

The application uses 8 Devise modules with enhanced configuration:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable,  # Password-based authentication
         :registerable,             # User registration
         :recoverable,              # Password reset functionality
         :rememberable,             # Remember me cookies
         :validatable,              # Email/password validation
         :confirmable,              # Email confirmation
         :trackable,                # Sign-in tracking
         :lockable                  # Account locking
end
```

#### Enhanced Settings
```ruby
# config/initializers/devise.rb
config.scoped_views = true                    # Custom views per scope
config.reconfirmable = true                   # Email change confirmation
config.expire_all_remember_me_on_sign_out = true
config.lock_strategy = :failed_attempts
config.unlock_keys = [:email]
config.unlock_strategy = :email
config.maximum_attempts = 5
config.unlock_in = 1.hour

# Turbo/Hotwire compatibility
config.navigational_formats = ['*/*', :html, :turbo_stream]
```

### Authentication Flow

```mermaid
flowchart TD
    Start([User Request]) --> Check{Authenticated?}
    
    Check -->|No| Login[Login Page]
    Check -->|Yes| StatusCheck{User Active?}
    
    Login --> Attempt[Login Attempt]
    Attempt --> Validate{Valid Credentials?}
    
    Validate -->|No| Increment[Increment Failed Attempts]
    Increment --> LockCheck{5+ Attempts?}
    LockCheck -->|Yes| Lock[Lock Account]
    LockCheck -->|No| Login
    
    Validate -->|Yes| EmailConfirmed{Email Confirmed?}
    EmailConfirmed -->|No| ConfirmPrompt[Confirmation Required]
    EmailConfirmed -->|Yes| CreateSession[Create Session]
    
    CreateSession --> StatusCheck
    StatusCheck -->|No| Logout[Force Logout]
    StatusCheck -->|Yes| Authorized[Continue to App]
    
    Lock --> Email[Send Unlock Email]
    Email --> End([Access Denied])
    Logout --> End
    ConfirmPrompt --> End
    Authorized --> App([Application])
```

### Password Security

#### Password Requirements
```ruby
# Strong password validation in User model
class User < ApplicationRecord
  validate :password_complexity, if: :password_required?
  
  private
  
  def password_complexity
    return if password.blank?
    
    errors.add(:password, "must be at least 8 characters") if password.length < 8
    errors.add(:password, "must include one uppercase letter") unless password =~ /[A-Z]/
    errors.add(:password, "must include one lowercase letter") unless password =~ /[a-z]/
    errors.add(:password, "must include one digit") unless password =~ /\d/
    errors.add(:password, "must include one special character") unless password =~ /[[:^alnum:]]/
  end
end
```

#### Password Storage
- Bcrypt encryption with cost factor 12
- Salted hashes stored in database
- No password history (future enhancement)

### Session Management

#### Session Configuration
```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :active_record_store,
  key: '_saas_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  expire_after: 24.hours
```

#### Session Security Features
- **Secure cookies** in production (HTTPS only)
- **HTTPOnly** flag prevents JavaScript access
- **SameSite** protection against CSRF
- **Session rotation** on privilege elevation
- **Activity timeout** after 24 hours

### Account Security Features

#### Email Confirmation
```ruby
# Required before first sign-in
class User < ApplicationRecord
  # Skip confirmation for invited users
  after_create :skip_confirmation_for_invited_users
  
  private
  
  def skip_confirmation_for_invited_users
    confirm if invited? || enterprise?
  end
end
```

#### Account Locking & Rate Limiting

#### Devise Locking Configuration
```ruby
# config/initializers/devise.rb
config.lock_strategy = :failed_attempts
config.unlock_keys = [:email]
config.unlock_strategy = :email
config.maximum_attempts = 5
config.unlock_in = 1.hour
```

#### Rack::Attack Rate Limiting
```ruby
# config/initializers/rack_attack.rb
# Fail2Ban-style blocking
Rack::Attack.blocklist('fail2ban:logins') do |req|
  Rack::Attack::Fail2Ban.filter("fail2ban:login-#{req.ip}", 
    maxretry: 3,      # 3 attempts
    findtime: 10.minutes,
    bantime: 10.minutes
  ) do
    req.path == '/users/sign_in' && req.post? && 
    req.env['rack.attack.matched'] == 'limit login attempts per ip'
  end
end

# Login attempt throttling
Rack::Attack.throttle('limit login attempts per ip', 
  limit: 5, 
  period: 1.minute
) do |req|
  req.ip if req.path == '/users/sign_in' && req.post?
end

# Password reset throttling
Rack::Attack.throttle('limit password resets per email', 
  limit: 3, 
  period: 1.hour
) do |req|
  req.params.dig('user', 'email')&.downcase if 
    req.path == '/users/password' && req.post?
end
```

#### Login Tracking & Activity Monitoring
```ruby
# Devise trackable provides:
# - sign_in_count
# - current_sign_in_at / last_sign_in_at
# - current_sign_in_ip / last_sign_in_ip

# Enhanced tracking with background jobs
class ApplicationController < ActionController::Base
  include ActivityTrackable
  
  # Track user activity asynchronously (5-minute cache)
  after_action :track_user_activity
  
  private
  
  def track_user_activity
    return unless current_user
    
    cache_key = "user_activity_#{current_user.id}"
    unless Rails.cache.exist?(cache_key)
      TrackUserActivityJob.perform_later(current_user)
      Rails.cache.write(cache_key, true, expires_in: 5.minutes)
    end
  end
end

# Admin activity tracking
class Admin::BaseController < ApplicationController
  after_action :track_admin_activity, except: [:index, :show]
  
  private
  
  def track_admin_activity
    TrackAdminActivityJob.perform_later(
      admin_user: current_user,
      controller: controller_name,
      action: action_name,
      path: request.path,
      method: request.method,
      params: request.filtered_parameters,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
```

## Authorization Architecture (Pundit)

### Policy-Based Authorization

```ruby
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Helper methods available to all policies
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
end
```

### Authorization Flow

```mermaid
flowchart TD
    Action[Controller Action] --> Auth{Authenticated?}
    Auth -->|No| Login[Redirect to Login]
    Auth -->|Yes| Load[Load Resource]
    
    Load --> Authorize[authorize @resource]
    Authorize --> Policy[Find Policy Class]
    Policy --> Method[Call Policy Method]
    
    Method --> Check{Authorized?}
    Check -->|Yes| Proceed[Execute Action]
    Check -->|No| Denied[Raise NotAuthorized]
    
    Denied --> Rescue[Rescue in Controller]
    Rescue --> Redirect[Redirect with Error]
    
    Proceed --> Verify[verify_authorized]
    Verify --> Response[Render Response]
```

### Policy Examples

#### User Policy
```ruby
class UserPolicy < ApplicationPolicy
  # Viewing permissions
  def show?
    # Admins can view anyone
    return true if admin?
    # Users can view themselves
    user == record
  end

  # Modification permissions
  def update?
    # Super admins can update anyone
    return true if super_admin?
    # Site admins cannot update super admins
    return false if record.super_admin? && site_admin?
    # Users can update themselves
    user == record
  end

  def destroy?
    # Only super admins can delete users
    return true if super_admin?
    # Team admins can delete team members
    team_admin_can_delete?
  end

  # Role management
  def change_role?
    super_admin? && user != record
  end

  # Scopes for index actions
  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.site_admin?
        scope.where.not(system_role: 'super_admin')
      elsif user.team_admin?
        scope.where(team: user.team)
      else
        scope.none
      end
    end
  end

  private

  def team_admin_can_delete?
    user.team_admin? && 
    record.invited? && 
    user.team_id == record.team_id
  end
end
```

#### Team Policy
```ruby
class TeamPolicy < ApplicationPolicy
  def show?
    # Admins can view any team
    return true if admin?
    # Members can view their team
    user.team_id == record.id
  end

  def create?
    # Only super admins create teams
    super_admin?
  end

  def update?
    # Super admins or team admins
    super_admin? || team_admin?
  end

  def manage_members?
    super_admin? || team_admin?
  end

  def manage_billing?
    super_admin? || (team_admin? && record.admin_id == user.id)
  end

  private

  def team_admin?
    user.team_id == record.id && user.team_role == 'admin'
  end
end
```

### Controller Integration

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  # Ensure authentication
  before_action :authenticate_user!
  
  # Ensure authorization
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  
  # Handle authorization failures
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    error_key = exception.query.to_s.remove('?')
    
    flash[:alert] = t("#{policy_name}.#{error_key}", 
                     scope: "pundit", 
                     default: :default)
    
    redirect_back_or_to(root_path)
  end
end
```

### Advanced Authorization Patterns

#### Context-Aware Policies
```ruby
class ProjectPolicy < ApplicationPolicy
  # Check team context
  def show?
    return true if admin?
    
    # User must be on the same team as the project
    if record.team.present?
      user.team_id == record.team_id
    else
      false
    end
  end

  # Role-based feature access
  def export?
    return true if admin?
    
    # Only team admins can export
    user.team_admin? && user.team_id == record.team_id
  end
end
```

#### Nested Resource Authorization
```ruby
class Teams::MembersController < ApplicationController
  before_action :set_team
  before_action :set_member, only: [:show, :update, :destroy]
  
  def destroy
    # Authorize both team and member
    authorize @team, :manage_members?
    authorize @member, :destroy?
    
    @member.destroy
    redirect_to team_members_path(@team)
  end
  
  private
  
  def set_team
    @team = Team.find_by!(slug: params[:team_slug])
    authorize @team, :show?
  end
  
  def set_member
    @member = @team.users.find(params[:id])
  end
end
```

## Email Change Security

### Email Change Request System
```ruby
# Prevents direct email changes
module EmailChangeProtection
  extend ActiveSupport::Concern
  
  included do
    # Block direct email updates
    before_save :prevent_email_change, if: :will_save_change_to_email?
  end
  
  private
  
  def prevent_email_change
    return if new_record?
    return if Thread.current[:authorized_email_change]
    
    # Super admins can change email directly
    return if Thread.current[:current_user]&.super_admin?
    
    errors.add(:email, "cannot be changed directly")
    throw :abort
  end
end

# Email change request workflow
class EmailChangeRequest < ApplicationRecord
  belongs_to :user
  belongs_to :approved_by, class_name: 'User', optional: true
  
  enum status: { pending: 0, approved: 1, rejected: 2 }
  
  scope :expired, -> { where('created_at < ?', 30.days.ago) }
  
  before_create :generate_token
  after_create :send_notification
  
  def approve!(admin)
    transaction do
      update!(status: 'approved', approved_by: admin, approved_at: Time.current)
      
      # Authorize the email change
      Thread.current[:authorized_email_change] = true
      old_email = user.email
      
      user.update!(email: new_email)
      
      # Security notifications
      UserMailer.email_changed_notification(user, old_email).deliver_later
      
      # Audit logging
      AuditLogService.log_security_event(
        user: admin,
        action: 'email_change.approve',
        target_user: user,
        details: { old_email: old_email, new_email: new_email }
      )
    ensure
      Thread.current[:authorized_email_change] = false
    end
  end
end
```

### Super Admin Direct Email Change
```ruby
class ProfilesController < ApplicationController
  def update
    if current_user.super_admin? && params[:user][:email].present?
      # Direct email change with audit logging
      old_email = current_user.email
      
      Thread.current[:authorized_email_change] = true
      if current_user.update(user_params)
        AuditLogService.log_security_event(
          user: current_user,
          action: 'email_change.direct',
          target_user: current_user,
          details: { old_email: old_email, new_email: current_user.email }
        )
      end
      Thread.current[:authorized_email_change] = false
    end
  end
end
```

## Security Middleware

### Warden Configuration
```ruby
# Devise uses Warden for authentication
Warden::Manager.after_authentication do |user, auth, opts|
  # Track successful authentication
  user.update_column(:last_sign_in_at, Time.current)
end

Warden::Manager.before_failure do |env, opts|
  # Log failed authentication attempts
  email = env['rack.request.form_hash']['user']['email'] rescue nil
  Rails.logger.warn "Failed login attempt for: #{email}"
end

Warden::Manager.before_logout do |user, auth, opts|
  # Clean up user session data
  auth.request.session.delete(:team_context)
end
```

### Custom Authentication Strategies
```ruby
# Team-specific authentication context
module TeamAuthenticationConcern
  extend ActiveSupport::Concern
  
  included do
    before_action :set_team_context
  end
  
  private
  
  def set_team_context
    return unless current_user&.invited?
    
    @current_team = current_user.team
    session[:team_context] = @current_team.slug
  end
  
  def require_team_member!
    unless current_user&.team_id == @team&.id
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
```

## CSRF Protection

### Implementation
```ruby
class ApplicationController < ActionController::Base
  # Standard Rails CSRF protection
  protect_from_forgery with: :exception
  
  # Enhanced for critical actions
  before_action :verify_critical_csrf_token, only: [:destroy, :transfer_ownership]
  
  private
  
  def verify_critical_csrf_token
    # Double-submit cookie pattern
    return if request.headers['X-CSRF-Token'] == form_authenticity_token
    
    # Log potential CSRF attempt
    Rails.logger.warn "CSRF token mismatch for #{current_user.email}"
    
    # Reject request
    render json: { error: 'Invalid request' }, status: :unprocessable_entity
  end
end
```

### JavaScript Integration
```javascript
// Stimulus controller for CSRF tokens
export default class extends Controller {
  connect() {
    // Add CSRF token to all AJAX requests
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    
    if (token) {
      window.axios.defaults.headers.common['X-CSRF-Token'] = token
    }
  }
  
  // Refresh token on session renewal
  refreshToken() {
    fetch('/csrf_token')
      .then(response => response.json())
      .then(data => {
        document.querySelector('meta[name="csrf-token"]').content = data.token
        window.axios.defaults.headers.common['X-CSRF-Token'] = data.token
      })
  }
}
```

## Multi-Factor Authentication (Prepared)

### Architecture Design
```ruby
# Future implementation structure
class User < ApplicationRecord
  # MFA attributes
  # otp_secret_key :string
  # otp_required_for_login :boolean
  # otp_backup_codes :text, array: true
  
  def enable_two_factor!
    update!(
      otp_secret_key: ROTP::Base32.random,
      otp_required_for_login: true,
      otp_backup_codes: generate_backup_codes
    )
  end
  
  def verify_otp(code)
    totp = ROTP::TOTP.new(otp_secret_key)
    totp.verify(code, drift_behind: 30)
  end
end
```

## API Authentication (Future)

### Token-Based Authentication
```ruby
# Planned API authentication
class ApiController < ActionController::API
  before_action :authenticate_api_user!
  
  private
  
  def authenticate_api_user!
    token = request.headers['Authorization']&.split(' ')&.last
    
    @current_api_user = User.find_by_api_token(token) if token
    
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_api_user
  end
end
```

### OAuth2 Provider (Planned)
```ruby
# OAuth2 application structure
class OauthApplication < ApplicationRecord
  belongs_to :owner, polymorphic: true
  has_many :access_tokens
  
  validates :name, presence: true
  validates :redirect_uri, presence: true, url: true
  
  before_create :generate_credentials
  
  private
  
  def generate_credentials
    self.client_id = SecureRandom.hex(16)
    self.client_secret = SecureRandom.hex(32)
  end
end
```

## Security Best Practices

### 1. Secure Headers
```ruby
# config/application.rb
config.force_ssl = true
config.ssl_options = { 
  hsts: { 
    subdomains: true, 
    preload: true, 
    expires: 1.year 
  } 
}
```

### 2. Parameter Filtering
```ruby
# Strong parameters in every controller
def user_params
  params.require(:user).permit(:first_name, :last_name, :email)
  # Never permit: :system_role, :user_type, :stripe_customer_id
end
```

### 3. SQL Injection Prevention
```ruby
# Always use parameterized queries
User.where("email = ?", params[:email])  # Good
User.where("email = '#{params[:email]}'")  # Bad - SQL injection risk
```

### 4. XSS Protection
```erb
<!-- Always escape user content -->
<%= @user.name %>  <!-- Escaped by default -->
<%== @user.bio %> <!-- Raw output - dangerous -->
<%= sanitize @user.bio, tags: %w[b i u] %> <!-- Controlled HTML -->
```

## Monitoring & Alerts

### Enhanced Audit Logging
```ruby
class AuditLogService
  # Security-specific event logging
  def self.log_security_event(user:, action:, target_user: nil, details: {})
    AuditLog.create!(
      user: user,
      target_user: target_user || user,
      action: action,
      details: details.merge(
        security_event: true,
        timestamp: Time.current,
        ip_address: Thread.current[:current_request]&.remote_ip
      )
    )
  end
  
  # Team action logging
  def self.log_team_action(user:, team:, action:, details: {})
    AuditLog.create!(
      user: user,
      action: "team.#{action}",
      details: details.merge(
        team_id: team.id,
        team_slug: team.slug
      )
    )
  end
  
  # System action logging
  def self.log_system_action(user:, action:, details: {})
    AuditLog.create!(
      user: user,
      action: "system.#{action}",
      details: details.merge(
        system_event: true,
        admin_role: user.system_role
      )
    )
  end
end
```

### Admin Activity Monitoring
```ruby
class AdminActivityLog < ApplicationRecord
  belongs_to :admin_user, class_name: 'User'
  
  # Suspicious activity detection
  scope :suspicious, -> {
    where("response_time_ms > ? OR path LIKE ?", 5000, '%destroy%')
  }
  
  scope :rapid_actions, -> { 
    select('admin_user_id, COUNT(*) as action_count')
    .where('created_at > ?', 5.minutes.ago)
    .group(:admin_user_id)
    .having('COUNT(*) > 50')
  }
  
  # Alert on unusual patterns
  def self.check_suspicious_activity
    rapid_actions.each do |activity|
      SecurityMailer.rapid_admin_actions_alert(
        User.find(activity.admin_user_id),
        activity.action_count
      ).deliver_later
    end
    
    # Check for unusual IP addresses
    unusual_ips = where('created_at > ?', 1.hour.ago)
      .group(:ip_address)
      .having('COUNT(DISTINCT admin_user_id) > 3')
      .count
      
    unusual_ips.each do |ip, count|
      SecurityMailer.unusual_ip_alert(ip, count).deliver_later
    end
  end
end
```

### Failed Authentication Monitoring
```ruby
# app/services/security_monitor_service.rb
class SecurityMonitorService
  def self.check_failed_logins
    # Alert on suspicious patterns
    User.locked.where('locked_at > ?', 1.hour.ago).find_each do |user|
      SecurityMailer.account_locked_notification(user).deliver_later
    end
    
    # Check for brute force attempts
    failed_ips = AuditLog
      .where(action: 'login.failed')
      .where('created_at > ?', 10.minutes.ago)
      .group(:ip_address)
      .count
      
    failed_ips.each do |ip, count|
      if count > 10
        Rack::Attack.blocklist("blocked-#{ip}") { |req| req.ip == ip }
        SecurityMailer.brute_force_alert(ip, count).deliver_later
      end
    end
  end
end
```

### Security Metrics Dashboard
```ruby
# app/models/security_metric.rb
class SecurityMetric
  def self.dashboard_stats
    {
      active_sessions: ActiveRecord::SessionStore::Session.active.count,
      locked_accounts: User.locked.count,
      failed_logins_today: AuditLog.where(action: 'login.failed').today.count,
      password_resets_today: User.where('reset_password_sent_at > ?', Date.current).count,
      suspicious_ips: Rack::Attack.blocked_ips.count,
      pending_email_changes: EmailChangeRequest.pending.count,
      admin_actions_today: AdminActivityLog.where('created_at > ?', Date.current).count
    }
  end
end
```

## Notification System Integration

### Authentication Notifications
```ruby
# Email change request notifications
class EmailChangeRequestNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = 'UserMailer'
    config.method = :email_change_request
  end
  
  deliver_by :database
  
  param :email_change_request
  
  def message
    "Email change requested to #{params[:email_change_request].new_email}"
  end
  
  def url
    email_change_request_url(params[:email_change_request])
  end
end

# Security alert notifications
class SecurityAlertNotifier < ApplicationNotifier
  deliver_by :email, if: :email_enabled?
  deliver_by :database
  
  param :alert_type
  param :details
  
  def message
    case params[:alert_type]
    when 'unusual_login'
      "Unusual login detected from #{params[:details][:ip]}"
    when 'email_changed'
      "Your email was changed to #{params[:details][:new_email]}"
    when 'password_changed'
      "Your password was changed"
    end
  end
  
  private
  
  def email_enabled?
    recipient.notification_preferences.dig('email', 'security_alerts')
  end
end
```

### Notification Preferences
```ruby
# User notification preferences structure
class User < ApplicationRecord
  # Default notification preferences
  after_initialize :set_default_notification_preferences
  
  private
  
  def set_default_notification_preferences
    self.notification_preferences ||= {
      'email' => {
        'enabled' => true,
        'frequency' => 'immediate',
        'security_alerts' => true,
        'status_changes' => true,
        'role_changes' => true
      },
      'in_app' => {
        'enabled' => true,
        'security_alerts' => true,
        'status_changes' => true
      },
      'real_time' => {
        'enabled' => false,
        'sound' => true
      }
    }
  end
end
```

## Testing Authentication & Authorization

### Authentication Tests
```ruby
class AuthenticationTest < ActionDispatch::IntegrationTest
  test "requires email confirmation" do
    user = create(:user, confirmed_at: nil)
    
    post user_session_path, params: { 
      user: { email: user.email, password: 'password' } 
    }
    
    assert_redirected_to new_user_session_path
    assert_equal 'You need to confirm your email', flash[:alert]
  end
  
  test "locks account after failed attempts" do
    user = create(:user)
    
    5.times do
      post user_session_path, params: { 
        user: { email: user.email, password: 'wrong' } 
      }
    end
    
    user.reload
    assert user.locked?
  end
end
```

### Authorization Tests
```ruby
class UserPolicyTest < ActiveSupport::TestCase
  test "super admin can update any user" do
    super_admin = create(:user, :super_admin)
    regular_user = create(:user)
    
    policy = UserPolicy.new(super_admin, regular_user)
    assert policy.update?
  end
  
  test "users cannot update others" do
    user1 = create(:user)
    user2 = create(:user)
    
    policy = UserPolicy.new(user1, user2)
    assert_not policy.update?
  end
end
```

---

## Advanced Security Features

### Suspicious Path & User Agent Blocking
```ruby
# config/initializers/rack_attack.rb
# Block suspicious paths
Rack::Attack.blocklist('block suspicious paths') do |req|
  suspicious_paths = %w[.php .asp .aspx .jsp .cgi .pl .py .sh .env wp-admin phpmyadmin]
  path = req.path.downcase
  
  suspicious_paths.any? { |ext| path.include?(ext) }
end

# Block bad user agents
Rack::Attack.blocklist('block bad user agents') do |req|
  bad_agents = %w[masscan nikto sqlmap havij acunetix netsparker]
  user_agent = req.user_agent.to_s.downcase
  
  bad_agents.any? { |agent| user_agent.include?(agent) }
end

# Custom responses
Rack::Attack.blocklisted_responder = lambda do |request|
  [ 403, 
    { 'Content-Type' => 'text/plain' }, 
    ["Forbidden - Your request has been blocked.\n"]
  ]
end

Rack::Attack.throttled_responder = lambda do |request|
  [ 429,
    { 'Content-Type' => 'text/plain', 'Retry-After' => '60' },
    ["Too Many Requests - Please try again later.\n"]
  ]
end
```

### Force Logout Mechanism
```ruby
class Users::StatusManagementService
  def deactivate_user(user, admin:, reason:)
    user.transaction do
      # Update status
      user.update!(status: 'inactive')
      
      # Force logout by resetting sign_in_count
      user.update_column(:sign_in_count, 0)
      
      # Invalidate remember token
      user.update_column(:remember_created_at, nil)
      
      # Clear all sessions
      ActiveRecord::SessionStore::Session
        .where("data LIKE ?", "%user_id: #{user.id}%")
        .destroy_all
      
      # Audit log
      AuditLogService.log_security_event(
        user: admin,
        action: 'user.deactivate',
        target_user: user,
        details: { reason: reason }
      )
    end
  end
end
```

---

**Last Updated**: January 2025
**Previous**: [Database Design](03-database-design.md)
**Next**: [Billing Architecture](05-billing-architecture.md)