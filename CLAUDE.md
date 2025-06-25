# Complete Team-Based SaaS Application Generator Prompt

Strong focus on readability and code must follow Rails best practices of Ruby and Ruby On Rails
**📋 DOCUMENTATION HAS BEEN ORGANIZED** 

This large specification file has been reorganized into focused documentation in the `docs/` folder:

- **[Security Guide](docs/security.md)** - Authentication, authorization, security best practices
- **[Bug Fixes & Troubleshooting](docs/bug_fixes.md)** - Rails 8.0.2 fixes and debugging
- **[Development Task List](docs/task_list.md)** - Implementation status and roadmap
- **[UI Components & Design System](docs/ui_components.md)** - Phosphor icons, Tailwind CSS, responsive design
- **[Common Pitfalls](docs/pitfalls.md)** - Anti-patterns and prevention strategies
- **[Testing Guide](docs/testing.md)** - Minitest setup, SimpleCov coverage, best practices
- **[Performance Optimizations](docs/performance_optimizations.md)** - Caching, background jobs, database indexes

**STATUS**: ✅ Production-ready Rails 8.0.2 SaaS application with comprehensive security, triple-track user system (Direct, Team, Enterprise), professional UI, Phosphor icon system, polymorphic invitation system, and Minitest/SimpleCov testing setup.

---

## Original Specification

Generate a complete Ruby on Rails 8 SaaS application with the following exact specifications:

## Application Architecture

### Core Concept
- **Triple-track SaaS application** with three distinct user ecosystems:
  - **Direct Users**: Individual users with personal billing who can also create teams
  - **Invited Users**: Team members who join via invitation only  
  - **Enterprise Users**: Large organizations with enterprise plans (invitation-based)
- **Teams operate independently** with their own URLs, billing, and members
- **Enterprise groups operate independently** with dedicated management interfaces
- **Individual users operate independently** with personal billing and features
- **Direct users CAN create and own teams** while maintaining individual features
- **No crossover** between invited team members and individual user features
- **Enterprise users are separate** from both direct and team users

### User Types & Access Patterns

#### System Administration Users
1. **Super Admin**
   - Platform owner with complete system access
   - Can create teams and enterprise groups
   - Can manage all users, teams, and enterprise organizations
   - Access: `/admin/super/dashboard`

2. **Site Admin** 
   - Customer support and user management
   - Cannot create teams or enterprise groups (read-only access)
   - Cannot modify billing but can view organization details
   - Can manage user status and provide support
   - Can view both teams and enterprise groups for support
   - Access: `/admin/site/dashboard`

#### Individual Users (Direct Registration)
3. **Direct User**
   - Registers independently via public signup
   - Can choose individual or team plans
   - Has personal Stripe subscription and billing
   - CAN create and own teams while maintaining individual features
   - Cannot join teams via invitation (but can create their own)
   - Access: `/dashboard` (individual) or `/teams/team-slug/` (if owns team)

#### Team-Based Users (Invitation Only)
4. **Team Admin**
   - Can be either:
     - Direct user who created a team (owns_team: true)
     - Invited user with admin role assigned
   - Manages team billing, settings, and members
   - Can invite new users (new emails only) and delete team members
   - Can revoke pending invitations (but not accepted ones)
   - Access: `/teams/team-slug/admin`

5. **Team Member**
   - Created through Team Admin invitation to new email addresses
   - No billing access, limited team permissions
   - Cannot become individual user or join other teams
   - Access: `/teams/team-slug/`

#### Enterprise Users (Invitation Only)
6. **Enterprise Admin**
   - Manages enterprise organization
   - Invited via email by Super Admin during group creation
   - Full access to member management, billing, and settings
   - Can invite/remove members and manage roles
   - Access: `/enterprise/enterprise-slug/`
   
7. **Enterprise Member**
   - Part of enterprise organization
   - Invited by Enterprise Admin
   - Standard access to enterprise features
   - Cannot access billing or member management
   - Access: `/enterprise/enterprise-slug/`

## Technical Stack

### Backend Dependencies
```ruby
# Core Rails
gem "rails", "~> 8.0.2"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"

# Frontend
gem "importmap-rails"
gem "turbo-rails" 
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

# Authentication & Authorization
gem "devise"
gem "pundit"
gem "pretender"

# UI Components
gem "rails_icons", "~> 1.0"
gem "pagy", "~> 7.0"

# Payment Processing
gem "stripe"
gem "pay"

# Analytics & Monitoring
gem "ahoy_matey"
gem "blazer"
gem "rails_charts"

# Performance & Storage
gem "activerecord-session_store"
gem "solid_cache"
gem "solid_queue" 
gem "solid_cable"
gem "bootsnap", require: false

# Security
gem "rack-attack"
gem "rack-cors"

# Deployment
gem "kamal", require: false
gem "thruster", require: false

# Development & Testing
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  
  # Testing
  gem "minitest", "~> 5.22"
  gem "minitest-rails", "~> 8.0"
  gem "minitest-reporters"
  gem "simplecov", require: false
  gem "faker"
  gem "capybara"
  gem "selenium-webdriver"
end

group :development do
  gem "web-console"
  gem "letter_opener"
end
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY,
  
  -- Devise Authentication
  email VARCHAR(255) UNIQUE NOT NULL,
  encrypted_password VARCHAR(255) NOT NULL,
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  confirmed_at TIMESTAMP,
  confirmation_token VARCHAR(255),
  reset_password_token VARCHAR(255),
  reset_password_sent_at TIMESTAMP,
  
  -- System Role (for platform administration)
  system_role ENUM('super_admin', 'site_admin', 'user') DEFAULT 'user',
  
  -- User Type & Status
  user_type ENUM('direct', 'invited', 'enterprise') DEFAULT 'direct',
  status ENUM('active', 'inactive', 'locked') DEFAULT 'active',
  
  -- Team Association (only for invited team users)
  team_id BIGINT REFERENCES teams(id),
  team_role ENUM('admin', 'member'),
  
  -- Enterprise Association (only for enterprise users)
  enterprise_group_id BIGINT REFERENCES enterprise_groups(id),
  enterprise_group_role ENUM('admin', 'member'),
  
  -- Individual Billing (only for direct users)
  stripe_customer_id VARCHAR(255), -- Pay gem will use this
  
  -- Activity Tracking
  last_sign_in_at TIMESTAMP,
  sign_in_count INTEGER DEFAULT 0,
  last_activity_at TIMESTAMP,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  -- Constraints
  CONSTRAINT user_type_check CHECK (
    (user_type = 'direct' AND team_id IS NULL AND team_role IS NULL AND enterprise_group_id IS NULL AND enterprise_group_role IS NULL) OR
    (user_type = 'invited' AND team_id IS NOT NULL AND team_role IS NOT NULL AND enterprise_group_id IS NULL AND enterprise_group_role IS NULL) OR
    (user_type = 'enterprise' AND team_id IS NULL AND team_role IS NULL AND enterprise_group_id IS NOT NULL AND enterprise_group_role IS NOT NULL)
  )
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_team_id ON users(team_id);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_last_activity ON users(last_activity_at);
```

### Teams Table
```sql
CREATE TABLE teams (
  id BIGINT PRIMARY KEY,
  
  -- Team Identity
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  
  -- Team Management
  admin_id BIGINT NOT NULL REFERENCES users(id),
  created_by_id BIGINT NOT NULL REFERENCES users(id), -- Super Admin
  
  -- Subscription & Billing
  plan ENUM('starter', 'pro', 'enterprise') DEFAULT 'starter',
  status ENUM('active', 'suspended', 'cancelled') DEFAULT 'active',
  stripe_customer_id VARCHAR(255), -- Pay gem will use this
  trial_ends_at TIMESTAMP,
  current_period_end TIMESTAMP,
  
  -- Configuration
  settings JSON,
  max_members INTEGER DEFAULT 5,
  custom_domain VARCHAR(255),
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_teams_slug ON teams(slug);
CREATE INDEX idx_teams_admin_id ON teams(admin_id);
CREATE INDEX idx_teams_status ON teams(status);
```

### Enterprise Groups Table
```sql
CREATE TABLE enterprise_groups (
  id BIGINT PRIMARY KEY,
  
  -- Group Identity
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  
  -- Group Management
  admin_id BIGINT REFERENCES users(id), -- Can be NULL during creation
  created_by_id BIGINT NOT NULL REFERENCES users(id), -- Super Admin
  
  -- Plan & Billing
  plan_id BIGINT NOT NULL REFERENCES plans(id),
  status ENUM('active', 'suspended', 'cancelled') DEFAULT 'active',
  stripe_customer_id VARCHAR(255), -- Pay gem integration
  trial_ends_at TIMESTAMP,
  current_period_end TIMESTAMP,
  
  -- Configuration
  settings JSON,
  max_members INTEGER DEFAULT 100,
  custom_domain VARCHAR(255),
  contact_email VARCHAR(255),
  contact_phone VARCHAR(255),
  billing_address TEXT,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_enterprise_groups_slug ON enterprise_groups(slug);
CREATE INDEX idx_enterprise_groups_admin_id ON enterprise_groups(admin_id);
CREATE INDEX idx_enterprise_groups_status ON enterprise_groups(status);
```

### Invitations Table (Polymorphic)
```sql
CREATE TABLE invitations (
  id BIGINT PRIMARY KEY,
  
  -- Legacy team support
  team_id BIGINT REFERENCES teams(id), -- Kept for backward compatibility
  
  -- Polymorphic association
  invitable_type VARCHAR(255), -- 'Team' or 'EnterpriseGroup'
  invitable_id BIGINT,
  invitation_type ENUM('team', 'enterprise') DEFAULT 'team',
  
  -- Invitation details
  email VARCHAR(255) NOT NULL,
  role ENUM('admin', 'member') DEFAULT 'member',
  token VARCHAR(255) UNIQUE NOT NULL,
  invited_by_id BIGINT NOT NULL REFERENCES users(id),
  
  accepted_at TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  -- Ensure email doesn't exist in users table
  CONSTRAINT no_existing_user CHECK (
    NOT EXISTS (SELECT 1 FROM users WHERE users.email = invitations.email)
  )
);

CREATE INDEX idx_invitations_token ON invitations(token);
CREATE INDEX idx_invitations_email ON invitations(email);
CREATE INDEX idx_invitations_invitable ON invitations(invitable_type, invitable_id);
CREATE INDEX idx_invitations_invitation_type ON invitations(invitation_type);
```

### Plans Table
```sql
CREATE TABLE plans (
  id BIGINT PRIMARY KEY,
  
  name VARCHAR(255) NOT NULL,
  plan_segment ENUM('individual', 'team', 'enterprise') NOT NULL,
  stripe_price_id VARCHAR(255), -- NULL for free plans
  amount_cents INTEGER DEFAULT 0,
  interval ENUM('month', 'year'),
  
  -- Plan Limits
  max_team_members INTEGER, -- Only for team plans
  features JSON, -- Array of feature identifiers
  
  active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Pay Gem Tables (Generated Automatically)
- `pay_subscriptions` - For both team and individual billing
- `pay_payment_methods` - Payment methods for teams and individuals  
- `pay_charges` - Transaction history
- `pay_webhook_endpoints` - Stripe webhook management

## User Flows & Business Logic

### 1. Direct User Registration Flow
```
1. User visits public signup page
2. User selects a plan (individual or team)
3. If team plan selected, team name field appears
4. System creates user with user_type: 'direct', status: 'active'
5. If team plan:
   - Creates team with user as admin
   - Sets owns_team: true
   - Redirects to /teams/team-slug/
6. If individual plan:
   - Redirects to /dashboard
7. User can set up Stripe subscription
8. Direct users CAN create teams later
```

### 2. Team Creation Flow (Super Admin Only)
```
1. Super Admin logs into /admin/super/dashboard
2. Super Admin creates new team with name and slug
3. Super Admin assigns existing user as Team Admin
4. System updates assigned user: team_id, team_role: 'admin'
5. Team gets unique URL: /teams/team-slug/
6. Team Admin can access /teams/team-slug/admin
7. Team gets Stripe customer and trial subscription
```

### 3. Team Invitation Flow
```
1. Team Admin visits /teams/team-slug/admin/invitations
2. Team Admin enters NEW email address (validated against users table)
3. System creates invitation record with unique token (expires in 7 days)
4. Email sent to invitee with invitation link
5. Invitee clicks link and sees invitation details
6. Invitee accepts invitation and is redirected to registration
7. Registration form is pre-filled with email (read-only)
8. No plan selection shown - only name and password fields
9. System creates user with:
   - user_type: 'invited'
   - team association from invitation
   - role from invitation (member/admin)
   - email confirmation skipped
10. Invitation marked as accepted
11. User redirected to team dashboard
```

### 3a. Direct User Team Creation Flow
```
1. Direct user registers and selects a team plan
2. Team name field appears dynamically
3. On successful registration:
   - User created with user_type: 'direct'
   - Team created with user as admin
   - User marked as owns_team: true
4. User redirected to team dashboard
5. Can invite members and manage team
```

### 4. User Status Management
```
Super Admin/Site Admin can:
- Set user status: active → inactive (user cannot sign in)
- Set user status: active → locked (user cannot sign in, security flag)
- Track user activity and sign-in patterns
- View user analytics and usage

Team Admin can:
- Delete team members (completely removes user account)
- Change team member roles (admin ↔ member)
- View team member activity
```

## Dashboard Specifications

### Super Admin Dashboard (`/admin/super/dashboard`)
**Features:**
- Platform-wide analytics (total users, teams, revenue)
- Team creation interface
- User management with status controls
- System settings and configuration
- Billing oversight for all teams and individuals
- User impersonation capabilities

**Navigation:**
- Dashboard overview
- Teams management
- Users management  
- System settings
- Analytics & reports

### Site Admin Dashboard (`/admin/site/dashboard`)
**Features:**
- User support and management tools
- User status management (active/inactive/locked)
- Activity monitoring and tracking
- Support ticket interface
- System health monitoring

**Navigation:**
- Dashboard overview
- Users management
- Support tools
- Activity reports

**Restrictions:**
- Cannot create teams
- Cannot access billing information
- Cannot access system settings

### Team Admin Dashboard (`/teams/team-slug/admin`)
**Features:**
- Team member management and deletion
- Team invitation system (new emails only)
- Team billing and subscription management
- Team settings and configuration
- Team analytics and usage metrics

**Navigation:**
- Admin dashboard
- Members management
- Invitations
- Billing & subscription
- Team settings
- Analytics

### Direct User Dashboard (`/dashboard`)
**Features:**
- Personal profile management
- Individual Stripe subscription management
- Personal analytics and usage
- Individual feature access
- Account settings

**Navigation:**
- Dashboard overview
- Billing & subscription
- Profile settings
- Features access

**Restrictions:**
- Cannot join teams
- Cannot be invited to teams
- No team-related functionality

### Team Member Dashboard (`/teams/team-slug/`)
**Features:**
- Team feature access
- Personal profile management
- Team activity feed
- Collaboration tools

**Navigation:**
- Team dashboard
- Team features
- Profile settings

**Restrictions:**
- No billing access
- Cannot invite other users
- Cannot delete team members
- Cannot access team settings

## URL Structure & Routing

### Public Routes
```ruby
root 'home#index'
devise_for :users
get '/pricing', to: 'pages#pricing'
get '/features', to: 'pages#features'
```

### Admin Routes
```ruby
namespace :admin do
  namespace :super do
    root 'dashboard#index'
    
    resources :teams do
      member do
        patch :assign_admin
        patch :change_status
        delete :destroy
      end
    end
    
    resources :users do
      member do
        patch :promote_to_site_admin
        patch :demote_from_site_admin
        patch :set_status
        get :activity
        post :impersonate
      end
    end
    
    resources :settings, only: [:index, :update]
    resources :analytics, only: [:index]
  end
  
  namespace :site do
    root 'dashboard#index'
    
    resources :users, only: [:index, :show] do
      member do
        patch :set_status
        get :activity
        post :impersonate
      end
    end
    
    resources :teams, only: [:index, :show]
    resources :support, only: [:index, :show, :update]
  end
end
```

### Direct User Routes
```ruby
scope '/dashboard' do
  root 'users/dashboard#index'
  
  namespace :users do
    resources :billing, only: [:index, :show, :edit, :update]
    resources :subscription, only: [:show, :edit, :update, :destroy]
    resources :profile, only: [:show, :edit, :update]
    resources :settings, only: [:index, :update]
  end
end
```

### Team Routes
```ruby
scope '/teams/:team_slug' do
  # Team member access
  root 'teams/dashboard#index', as: :team_root
  
  namespace :teams do
    resources :profile, only: [:show, :edit, :update]
    resources :features # Team-specific features
  end
  
  # Team admin routes
  scope '/admin' do
    root 'teams/admin/dashboard#index', as: :team_admin_root
    
    namespace :teams, path: '' do
      namespace :admin do
        resources :members do
          member do
            patch :change_role
            delete :destroy # Complete account deletion
          end
        end
        
        resources :invitations do
          member do
            post :resend
            delete :revoke
          end
        end
        
        resources :billing, only: [:index, :show]
        resources :subscription, only: [:show, :edit, :update, :destroy]
        resources :settings, only: [:index, :update]
        resources :analytics, only: [:index]
      end
    end
  end
end
```

### Public Invitation Routes
```ruby
resources :invitations, only: [:show] do
  member do
    patch :accept
    patch :decline
  end
end
```

## Authorization & Security

### Pundit Policies

#### Application Policy
```ruby
class ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def super_admin?
    @user&.system_role == 'super_admin'
  end

  def site_admin?
    @user&.system_role == 'site_admin'
  end

  def admin?
    super_admin? || site_admin?
  end

  def active_user?
    @user&.status == 'active'
  end
end
```

#### User Policy
```ruby
class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || @user == @record
  end

  def set_status?
    admin?
  end

  def impersonate?
    admin?
  end

  def destroy?
    super_admin? || (team_admin? && same_team?)
  end

  private

  def team_admin?
    @user&.team_role == 'admin'
  end

  def same_team?
    @user&.team_id == @record&.team_id
  end
end
```

#### Team Policy
```ruby
class TeamPolicy < ApplicationPolicy
  def show?
    super_admin? || site_admin? || team_member?
  end

  def create?
    super_admin?
  end

  def update?
    super_admin? || team_admin?
  end

  def destroy?
    super_admin?
  end

  def admin_access?
    super_admin? || team_admin?
  end

  private

  def team_member?
    @user&.team_id == @record&.id
  end

  def team_admin?
    @user&.team_id == @record&.id && @user&.team_role == 'admin'
  end
end
```

### Security Middleware
```ruby
# application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!
  before_action :check_user_status
  before_action :track_user_activity
  after_action :verify_authorized, except: [:index, :show]

  private

  def check_user_status
    if current_user && current_user.status != 'active'
      sign_out current_user
      redirect_to new_user_session_path, 
        alert: 'Your account has been deactivated.'
    end
  end

  def track_user_activity
    if current_user
      current_user.update_column(:last_activity_at, Time.current)
    end
  end
end
```

## Billing Integration

### Stripe Configuration
```ruby
# config/initializers/stripe.rb
Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  secret_key: ENV['STRIPE_SECRET_KEY'],
  webhook_secret: ENV['STRIPE_WEBHOOK_SECRET']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
```

### Pay Gem Setup
```ruby
# config/initializers/pay.rb
Pay.setup do |config|
  config.chargeable_model = 'User'
  config.billable_models = ['User', 'Team']
  config.business_name = "Your SaaS App"
  config.business_address = "123 Business St, City, State 12345"
  config.application_name = "Your SaaS"
  config.support_email = "support@yoursaas.com"
end
```

### Subscription Plans
```ruby
# Individual User Plans
individual_plans = [
  {
    name: 'Individual Free',
    plan_type: 'individual',
    amount_cents: 0,
    features: ['basic_dashboard', 'email_support']
  },
  {
    name: 'Individual Pro',
    plan_type: 'individual',
    stripe_price_id: 'price_individual_pro',
    amount_cents: 1900,
    interval: 'month',
    features: ['basic_dashboard', 'advanced_features', 'priority_support']
  },
  {
    name: 'Individual Premium',
    plan_type: 'individual',
    stripe_price_id: 'price_individual_premium',
    amount_cents: 4900,
    interval: 'month',
    features: ['basic_dashboard', 'advanced_features', 'premium_features', 'phone_support']
  }
]

# Team Plans
team_plans = [
  {
    name: 'Team Starter',
    plan_type: 'team',
    stripe_price_id: 'price_team_starter',
    amount_cents: 4900,
    interval: 'month',
    max_team_members: 5,
    features: ['team_dashboard', 'collaboration', 'email_support']
  },
  {
    name: 'Team Pro',
    plan_type: 'team',
    stripe_price_id: 'price_team_pro',
    amount_cents: 9900,
    interval: 'month',
    max_team_members: 15,
    features: ['team_dashboard', 'collaboration', 'advanced_team_features', 'priority_support']
  },
  {
    name: 'Team Enterprise',
    plan_type: 'team',
    stripe_price_id: 'price_team_enterprise',
    amount_cents: 19900,
    interval: 'month',
    max_team_members: 100,
    features: ['team_dashboard', 'collaboration', 'advanced_team_features', 'enterprise_features', 'phone_support']
  }
]
```

## Model Implementations

### User Model
```ruby
class User < ApplicationRecord
  include Pay::Billable # For individual user billing
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  belongs_to :team, optional: true
  has_many :created_teams, class_name: 'Team', foreign_key: 'created_by_id'
  has_many :administered_teams, class_name: 'Team', foreign_key: 'admin_id'
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'invited_by_id'

  enum system_role: { user: 0, site_admin: 1, super_admin: 2 }
  enum user_type: { direct: 0, invited: 1 }
  enum status: { active: 0, inactive: 1, locked: 2 }
  enum team_role: { member: 0, admin: 1 }

  validates :user_type, presence: true
  validates :status, presence: true
  
  # Validation: direct users cannot have team associations
  validates :team_id, absence: true, if: :direct?
  validates :team_role, absence: true, if: :direct?
  
  # Validation: invited users must have team associations
  validates :team_id, presence: true, if: :invited?
  validates :team_role, presence: true, if: :invited?

  scope :active, -> { where(status: 'active') }
  scope :direct_users, -> { where(user_type: 'direct') }
  scope :team_members, -> { where(user_type: 'invited') }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def can_sign_in?
    active?
  end

  def team_admin?
    invited? && team_role == 'admin'
  end

  def team_member?
    invited? && team_role == 'member'
  end
end
```

### Team Model
```ruby
class Team < ApplicationRecord
  include Pay::Billable # For team billing

  belongs_to :admin, class_name: 'User'
  belongs_to :created_by, class_name: 'User'
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, dependent: :destroy

  enum plan: { starter: 0, pro: 1, enterprise: 2 }
  enum status: { active: 0, suspended: 1, cancelled: 2 }

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :admin_id, presence: true
  validates :created_by_id, presence: true

  before_validation :generate_slug, if: :name_changed?

  scope :active, -> { where(status: 'active') }

  def to_param
    slug
  end

  def member_count
    users.count
  end

  def can_add_members?
    member_count < max_members
  end

  def plan_features
    case plan
    when 'starter'
      ['team_dashboard', 'collaboration', 'email_support']
    when 'pro'
      ['team_dashboard', 'collaboration', 'advanced_team_features', 'priority_support']
    when 'enterprise'
      ['team_dashboard', 'collaboration', 'advanced_team_features', 'enterprise_features', 'phone_support']
    end
  end

  private

  def generate_slug
    return unless name.present?
    
    base_slug = name.downcase.gsub(/[^a-z0-9\s\-]/, '').gsub(/\s+/, '-')
    counter = 0
    potential_slug = base_slug
    
    while Team.exists?(slug: potential_slug)
      counter += 1
      potential_slug = "#{base_slug}-#{counter}"
    end
    
    self.slug = potential_slug
  end
end
```

### Invitation Model
```ruby
class Invitation < ApplicationRecord
  belongs_to :team
  belongs_to :invited_by, class_name: 'User'

  enum role: { member: 0, admin: 1 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  
  validate :email_not_in_users_table
  validate :not_expired, on: :accept

  before_validation :generate_token, if: :new_record?
  before_validation :set_expiration, if: :new_record?

  scope :pending, -> { where(accepted_at: nil) }
  scope :active, -> { where('expires_at > ?', Time.current) }

  def to_param
    token
  end

  def expired?
    expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user_attributes = {})
    return false if expired? || accepted?

    User.transaction do
      user = User.create!(
        email: email,
        user_type: 'invited',
        team: team,
        team_role: role,
        status: 'active',
        **user_attributes
      )
      
      update!(accepted_at: Time.current)
      user
    end
  end

  private

  def email_not_in_users_table
    if User.exists?(email: email)
      errors.add(:email, 'already has an account')
    end
  end

  def not_expired
    if expired?
      errors.add(:base, 'Invitation has expired')
    end
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at = 7.days.from_now
  end
end
```

## Service Objects

### Team Creation Service
```ruby
class Teams::CreationService
  def initialize(super_admin, team_params, admin_user)
    @super_admin = super_admin
    @team_params = team_params
    @admin_user = admin_user
  end

  def call
    return failure('Only super admins can create teams') unless @super_admin.super_admin?
    return failure('Admin user must exist') unless @admin_user&.persisted?
    return failure('Admin user already has a team') if @admin_user.team.present?

    Team.transaction do
      team = create_team
      assign_admin(team)
      setup_billing(team)
      send_notifications(team)
      
      success(team)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def create_team
    Team.create!(
      name: @team_params[:name],
      admin: @admin_user,
      created_by: @super_admin,
      plan: @team_params[:plan] || 'starter',
      max_members: plan_member_limit(@team_params[:plan])
    )
  end

  def assign_admin(team)
    @admin_user.update!(
      user_type: 'invited',
      team: team,
      team_role: 'admin'
    )
  end

  def setup_billing(team)
    # Create Stripe customer for team
    customer = team.set_payment_processor(:stripe)
    
    # Start trial if applicable
    if team.starter?
      team.update!(trial_ends_at: 14.days.from_now)
    end
  end

  def send_notifications(team)
    TeamMailer.admin_assigned(team, @admin_user).deliver_later
  end

  def plan_member_limit(plan)
    case plan
    when 'starter' then 5
    when 'pro' then 15
    when 'enterprise' then 100
    else 5
    end
  end

  def success(team)
    OpenStruct.new(success?: true, team: team)
  end

  def failure(message)
    OpenStruct.new(success?: false, error: message)
  end
end
```

### User Status Management Service
```ruby
class Users::StatusManagementService
  def initialize(admin_user, target_user, new_status)
    @admin_user = admin_user
    @target_user = target_user
    @new_status = new_status
  end

  def call
    return failure('Unauthorized') unless can_manage_user_status?
    return failure('Invalid status') unless valid_status?

    @target_user.transaction do
      old_status = @target_user.status
      @target_user.update!(status: @new_status)
      
      log_status_change(old_status)
      send_notification_if_needed(old_status)
      force_signout_if_needed
      
      success
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def can_manage_user_status?
    @admin_user.super_admin? || @admin_user.site_admin?
  end

  def valid_status?
    %w[active inactive locked].include?(@new_status)
  end

  def log_status_change(old_status)
    AuditLog.create!(
      user: @admin_user,
      action: 'status_change',
      target_user: @target_user,
      details: {
        old_status: old_status,
        new_status: @new_status,
        timestamp: Time.current
      }
    )
  end

  def send_notification_if_needed(old_status)
    if old_status == 'active' && @new_status != 'active'
      UserStatusMailer.account_deactivated(@target_user, @new_status).deliver_later
    elsif old_status != 'active' && @new_status == 'active'
      UserStatusMailer.account_reactivated(@target_user).deliver_later
    end
  end

  def force_signout_if_needed
    if @new_status != 'active'
      # Force user logout by clearing all sessions
      @target_user.update_column(:sign_in_count, 0)
    end
  end

  def success
    OpenStruct.new(success?: true)
  end

  def failure(message)
    OpenStruct.new(success?: false, error: message)
  end
end
```

## Environment Configuration

```bash
# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Application Settings
APP_DOMAIN=yoursaas.com
DEFAULT_FROM_EMAIL=noreply@yoursaas.com
SUPPORT_EMAIL=support@yoursaas.com

# Database
DATABASE_URL=sqlite3://db/production.sqlite3

# Redis (for caching and jobs)
REDIS_URL=redis://localhost:6379/0

# Email (production)
SMTP_ADDRESS=smtp.youremailprovider.com
SMTP_PORT=587
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password

# Security
SECRET_KEY_BASE=your_secret_key_base
```

## Deployment & Production Considerations

### Docker Configuration
```dockerfile
FROM ruby:3.2-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
  build-essential \
  libsqlite3-dev \
  nodejs \
  npm \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json package-lock.json ./
RUN npm install

COPY . .

RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### Database Migrations Strategy
```ruby
# Migration order for production deployment:
# 1. Create users table
# 2. Create teams table  
# 3. Create invitations table
# 4. Create plans table
# 5. Install Pay gem migrations
# 6. Add indexes for performance
# 7. Add foreign key constraints
```

### Monitoring & Analytics
```ruby
# config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    # Only track for active users
    return unless data[:user_id] && User.active.exists?(data[:user_id])
    
    super
  end

  def track_event(data)
    # Add team context for invited users
    if data[:user_id]
      user = User.find(data[:user_id])
      if user.invited? && user.team
        data[:properties][:team_id] = user.team.id
        data[:properties][:team_slug] = user.team.slug
      end
    end
    
    super
  end
end
```

## Final Implementation Notes

### Critical Business Rules
1. **Direct users CANNOT join teams under any circumstances**
2. **Invitations can ONLY be sent to emails not in the users table**
3. **Team members CANNOT become direct users**  
4. **Only Super Admins can create teams**
5. **Team Admins can completely delete team member accounts**
6. **Each team has a unique URL structure**
7. **Billing is completely separate for teams vs individuals**

### Performance Considerations
- Index all foreign keys and frequently queried columns
- Use database constraints to enforce business rules
- Implement proper caching for team lookups by slug
- Use background jobs for email sending and billing operations
- Monitor N+1 queries in team member listings

### Security Requirements
- Validate team slug access on every team-scoped request
- Implement proper CSRF protection on all forms
- Use strong parameters for all controller actions
- Validate user status on every authenticated request
- Implement rate limiting on invitation sending

---

## 📚 For Implementation Details, Bug Fixes & More

**All implementation status, debugging guides, security details, and troubleshooting information has been moved to organized documentation:**

- **[Security Guide](docs/security.md)** - Complete security implementation details
- **[Bug Fixes & Troubleshooting](docs/bug_fixes.md)** - Rails 8.0.2 fixes and solutions  
- **[Development Task List](docs/task_list.md)** - Current progress and future roadmap
- **[Common Pitfalls](docs/pitfalls.md)** - Anti-patterns and prevention strategies

**This file now contains only the essential specification needed for development.**

## Recent Architectural Updates (June 2025)

### 1. User Type System Refactoring
- Removed redundancy between `plan_type` and `plan_segment`
- Implemented three distinct user types:
  - **Direct**: Can register, choose plans, and create teams
  - **Invited**: Join via team invitations only
  - **Enterprise**: Managed through enterprise groups (future feature)

### 2. Team Creation by Direct Users
- Direct users can now select team plans during registration
- Dynamic team name field appears when team plan is selected
- Creates team with user as admin and sets `owns_team: true`
- Maintains separation between direct and invited user features

### 3. Enhanced Invitation System
- Invitations expire after 7 days
- Email validation ensures no duplicate users
- Invited users skip email confirmation
- Invitation status properly tracked (pending/accepted/expired)
- Cannot revoke accepted invitations (user already exists)
- Improved UI with status badges and contextual actions

### 4. Registration Flow Improvements
- Conditional UI based on user type (direct vs invited)
- Plan selection only for direct users
- Pre-filled, read-only email for invited users
- Team information display for invited users
- Virtual attributes (`team_name`, `accepting_invitation`) for cleaner code

### 5. Redirect Logic
- Super/Site Admins → Admin dashboards
- Direct users with teams → Team dashboard
- Direct users without teams → Individual dashboard
- Invited users → Team dashboard
- Enterprise users → Enterprise dashboard (future)

## Testing Instructions

### Running Tests

```bash
# Run all tests
bundle exec rails test

# Run specific test file
bundle exec rails test test/models/user_test.rb

# Run tests with coverage report
bundle exec rails test
open coverage/index.html
```

### Writing Tests

The project uses Minitest with helpful authentication helpers:

```ruby
# In your test file
require "test_helper"

class YourTest < ActiveSupport::TestCase
  def setup
    @user = sign_in_with(
      email: "test@example.com",
      system_role: "super_admin",
      user_type: "direct"
    )
  end
  
  test "your test case" do
    assert @user.super_admin?
  end
end
```

## Recent Architectural Updates (June 2025)

### 1. Enterprise Groups Implementation
- Complete enterprise organization management system
- Invitation-based admin assignment (no circular dependencies)
- Purple-themed enterprise dashboard at `/enterprise/enterprise-slug/`
- Enterprise admins can manage members and settings
- Separate billing and feature access for enterprise organizations

### 2. Polymorphic Invitation System
- Invitations now support both teams and enterprise groups
- `invitable` polymorphic association for flexibility
- `invitation_type` enum distinguishes between team and enterprise invitations
- Proper handling in registration controller for all invitation types
- Email notifications with Letter Opener integration in development

### 3. Enhanced User Type System
- Three distinct user types: Direct, Invited, Enterprise
- Direct users can register and create teams
- Invited users join via team invitations only
- Enterprise users join via enterprise group invitations
- No crossover between different user types

### 4. Enterprise Dashboard Features
- Complete enterprise namespace with controllers and views
- Member management interface
- Quick actions for enterprise admins
- Consistent purple theme throughout enterprise UI
- Proper authorization and access control

### 5. Bug Fixes and Improvements
- Fixed site admin navigation to prevent unauthorized team creation
- Resolved circular dependency in enterprise group creation
- Fixed invitation acceptance status updates
- Proper icon helper usage (`icon` not `rails_icon`)
- Pundit policy scoping for enterprise controllers

### Test Coverage

SimpleCov is configured to track both line and branch coverage. Current coverage is ~24% with a target of 90%+.

See [Testing Guide](docs/testing.md) for comprehensive testing documentation.

# Important Instructions

## Linting
Run linting with:
```bash
bundle exec rubocop              # Check for issues
bundle exec rubocop --autocorrect # Auto-fix issues
```

## Testing  
Run tests with:
```bash
bundle exec rails test           # Run all tests
bundle exec rails test -v        # Verbose output
```

## Development Guidelines
- Do what has been asked; nothing more, nothing less
- NEVER create files unless they're absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User
- Always run linting after making changes
- Write tests for new functionality
- Try to update the files if existing rather than creating new files to avoid duplicacy. This is especially useful for docs and test files