# Complete Team-Based SaaS Application Generator Prompt

Strong focus on readability and code must follow Rails best practices of Ruby and Ruby On Rails
**📋 DOCUMENTATION HAS BEEN ORGANIZED** 

This large specification file has been reorganized into focused documentation in the `docs/` folder:

### Architecture & Technical Documentation
- **[Architecture Overview](docs/architecture/)** - System design, user architecture, database schema
- **[Security Documentation](docs/security/)** - Authentication, authorization, best practices
- **[Testing Documentation](docs/testing/)** - Strategy, coverage reports, prioritization
- **[Development Guides](docs/guides/)** - Business logic, performance, common pitfalls

### Implementation & Reference
- **[Bug Fixes](docs/bug_fixes.md)** - Rails 8.0.2 fixes and debugging
- **[UI Components](docs/reference/ui-components.md)** - Phosphor icons, Tailwind CSS
- **[Recent Updates](docs/RECENT_UPDATES.md)** - Latest changes and improvements
- **[Project Status](docs/project_status.md)** - Current state and roadmap

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

**📚 See [Database Design Documentation](docs/architecture/03-database-design.md) for complete schema details**

The application uses 25+ production tables with 50+ optimized indexes:

- **Core Tables**: users, teams, enterprise_groups, invitations, plans
- **Authentication**: Full Devise setup with lockable, trackable, confirmable
- **Billing**: Pay gem integration with Stripe (pay_customers, pay_subscriptions, etc.)
- **Audit/Analytics**: audit_logs, admin_activity_logs, ahoy_visits, ahoy_events
- **Notifications**: noticed_events, noticed_notifications, notification_categories
- **Support Tables**: email_change_requests, user_preferences, sessions, cache

## User Flows & Business Logic

**📚 See [User Flow Diagrams](docs/architecture/diagrams/user-flows.md) for detailed flow charts and sequences**

### Key User Flows:
1. **Direct User Registration** - Individual or team plan selection with dynamic UI
2. **Team Creation** - Super Admin only, with admin assignment
3. **Team Invitation** - 7-day expiry, email validation, polymorphic support
4. **Enterprise Flow** - Invitation-based admin assignment
5. **User Status Management** - Active/inactive/locked states with audit logging

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

**📚 See [Authentication & Authorization Documentation](docs/architecture/04-authentication.md) for complete security details**

### Key Security Features:
- **Authentication**: Devise with 8 security modules
- **Authorization**: Pundit policy-based system
- **Rate Limiting**: Comprehensive Rack::Attack configuration with Fail2Ban
- **Email Security**: Email change approval workflow with 30-day expiration
- **Activity Tracking**: Background job-based with 5-minute Redis cache
- **Session Security**: Server-side sessions, CSRF protection, secure cookies

### Security Documentation:
- **[Security Overview](docs/security/README.md)** - Complete security architecture
- **[Authentication Guide](docs/security/authentication.md)** - Devise configuration
- **[Authorization Guide](docs/security/authorization.md)** - Pundit policies
- **[Rack::Attack Config](docs/security/rack-attack.md)** - Rate limiting details

## Billing Integration

**💳 Stripe & Pay Gem Integration**

The application uses the Pay gem for comprehensive billing:
- **Individual Plans**: Free, Pro ($19/mo), Premium ($49/mo)
- **Team Plans**: Starter ($49/mo, 5 users), Pro ($99/mo, 15 users), Enterprise ($199/mo, 100 users)
- **Enterprise Plans**: Custom pricing and features

Billing is completely separated between user types with polymorphic Pay::Billable implementation.

## Model Architecture

**📚 See [User Architecture Documentation](docs/architecture/02-user-architecture.md) for complete model details**

The application implements a sophisticated triple-track user system with these core models:

- **User**: Polymorphic behavior based on user_type (direct, invited, enterprise)
- **Team**: Multi-tenant teams with Stripe billing integration
- **EnterpriseGroup**: Large organization management
- **Invitation**: Polymorphic invitations for teams and enterprises
- **EmailChangeRequest**: Secure email change workflow
- **AuditLog**: Comprehensive activity tracking

All models are implemented with proper validations, callbacks, and business logic enforcement at the database level.

## Service Objects & Business Logic

**📚 See [Business Logic Guide](docs/guides/business-logic.md) for service object patterns**

The application uses service objects for complex operations:

- **Teams::CreationService** - Team creation with admin assignment
- **Users::StatusManagementService** - User status changes with audit logging
- **EmailChangeService** - Secure email change workflow
- **InvitationService** - Polymorphic invitation handling
- **AuditLogService** - Centralized audit logging

All service objects follow the same pattern with `call` method and success/failure responses.

## Environment Configuration

**🔧 See `.env.example` for required environment variables**

Key configuration areas:
- **Stripe**: API keys and webhook secrets
- **Email**: SMTP settings for production
- **Database**: PostgreSQL for production
- **Redis**: Caching and background jobs
- **Security**: Secret keys and tokens

## Deployment & Production

**🚀 Production Deployment Requirements:**

- **Infrastructure**: Docker-ready with Kamal deployment support
- **Database**: PostgreSQL with proper migrations strategy
- **Background Jobs**: Solid Queue with Redis
- **Monitoring**: Ahoy analytics with team context tracking
- **Performance**: 50+ database indexes, query optimization
- **Security**: Rack::Attack rate limiting, secure headers

**Pending Production Tasks:**
- [ ] Production Stripe webhook setup
- [ ] Email delivery configuration
- [ ] Redis production configuration
- [ ] PostgreSQL migration from SQLite

## Final Implementation Notes

### Critical Business Rules
1. **Direct users CANNOT join teams under any circumstances**
2. **Invitations can ONLY be sent to emails not in the users table**
3. **Team members CANNOT become direct users**  
4. **Only Super Admins can create teams**
5. **Team Admins can completely delete team member accounts**
6. **Each team has a unique URL structure**
7. **Billing is completely separate for teams vs individuals**

### Performance & Security

**📚 See [Performance Guide](docs/guides/performance-guide.md) and [Security Best Practices](docs/security/best-practices.md)**

**Key Optimizations:**
- 60-80% reduction in page load times
- N+1 queries eliminated with query objects
- Background job processing with 5-minute cache
- Fragment and model caching implemented

**Security Features:**
- Comprehensive Rack::Attack rate limiting
- Email change approval workflow
- Force logout mechanism
- Audit logging for all admin actions

---

## 📚 For Implementation Details, Bug Fixes & More

**All implementation status, debugging guides, security details, and troubleshooting information has been moved to organized documentation:**

- **[Complete Documentation Hub](docs/README.md)** - All documentation organized by topic
- **[Architecture Documentation](docs/architecture/)** - System design and technical details
- **[Security Documentation](docs/security/)** - Comprehensive security implementation
- **[Testing Documentation](docs/testing/)** - Testing strategy and guides

**This file now contains only the essential specification needed for development.**

## Recent Architectural Updates

**📚 See [Recent Updates](docs/RECENT_UPDATES.md) and [Project Status](docs/project_status.md) for all changes**

## Testing

**📚 See [Testing Documentation](docs/testing/) for comprehensive testing guides**

- **[Testing Strategy](docs/testing/01-testing-strategy.md)** - Overall approach
- **[Test Coverage](docs/testing/02-test-coverage.md)** - Current metrics (1.33%)
- **[Test Prioritization](docs/testing/03-test-prioritization.md)** - What to test first
- **[Business Rule Testing](docs/testing/04-business-rule-testing.md)** - Critical tests

**Quick Start:**
```bash
bundle exec rails test           # Run all tests
bundle exec rails test -v        # Verbose output
```

### Key Recent Updates (January 2025)

1. **Documentation Consolidation** - All docs organized and updated
2. **UI/UX Overhaul** - Tailwind UI sidebar, improved navigation
3. **Enhanced Security** - Rack::Attack with Fail2Ban, email change security
4. **Performance Optimizations** - Background jobs, 50+ indexes, query objects
5. **Notification System** - Noticed gem integration complete
6. **Enterprise Features** - Purple-themed UI, polymorphic invitations

**Current Health**: 🔴 Test Coverage: 1.33% | 🟡 Code Quality: 253 RuboCop offenses | ✅ Performance: <100ms

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