# SaaS Rails Application Architecture

## Overview

This is a comprehensive **Team-Based SaaS Rails 8.0.2 application** built with a unique dual-track user system that completely separates individual users from team-based users. The application implements a sophisticated multi-tenant architecture with enterprise-grade authentication, authorization, and billing systems.

## Core Architecture Principles

### 1. Dual-Track User System
The application maintains two completely isolated user ecosystems:

- **Individual Users**: Register directly, have personal billing, operate independently
- **Team Users**: Invitation-only, share team billing, collaborate within teams

There is **no crossover** between these systems - a user cannot be both an individual user and a team member.

### 2. Multi-Tenant Architecture
- Teams operate as isolated tenants with unique URLs (`/teams/:team_slug`)
- Complete data isolation between teams
- Shared infrastructure with logical separation

### 3. Role-Based Access Control (RBAC)
Hierarchical permission system with five distinct user types:
1. **Super Admin**: Platform owner with complete system access
2. **Site Admin**: Customer support with limited admin access
3. **Direct User**: Individual users with personal accounts
4. **Team Admin**: Team managers with billing and member control
5. **Team Member**: Basic team users with limited permissions

## Directory Structure

```
saas_ror_starter/
├── app/
│   ├── controllers/
│   │   ├── admin/
│   │   │   ├── super/         # Super admin controllers
│   │   │   └── site/          # Site admin controllers
│   │   ├── teams/
│   │   │   ├── admin/         # Team admin controllers
│   │   │   └── [features]     # Team member controllers
│   │   ├── users/             # Individual user controllers
│   │   └── [public]           # Public-facing controllers
│   ├── models/
│   │   ├── user.rb            # Central user model
│   │   ├── team.rb            # Team management
│   │   ├── invitation.rb      # Invitation system
│   │   └── plan.rb            # Subscription plans
│   ├── services/              # Business logic encapsulation
│   │   ├── teams/
│   │   └── users/
│   ├── policies/              # Pundit authorization policies
│   ├── views/                 # ERB templates with Tailwind CSS
│   ├── mailers/              # Email functionality
│   └── javascript/           # Stimulus controllers & Turbo
├── config/                   # Rails configuration
├── db/
│   ├── migrate/              # Database migrations
│   └── schema.rb             # Current database schema
├── docs/                     # Comprehensive documentation
│   ├── security.md           # Security implementation
│   ├── bug_fixes.md          # Rails 8 compatibility fixes
│   ├── task_list.md          # Development roadmap
│   └── pitfalls.md           # Common issues & solutions
├── spec/                     # RSpec test suite
└── public/                   # Static assets
```

## Key Components

### Models Layer

#### User Model (`app/models/user.rb`)
The central authentication model with complex role management:

```ruby
class User < ApplicationRecord
  # Devise modules for authentication
  devise :database_authenticatable, :registerable, :recoverable, 
         :rememberable, :validatable, :confirmable, :trackable, :lockable

  # Pay gem for Stripe billing (individual users only)
  include Pay::Billable

  # Enums for role management
  enum system_role: { user: 0, site_admin: 1, super_admin: 2 }
  enum user_type: { direct: 0, invited: 1 }
  enum status: { active: 0, inactive: 1, locked: 2 }
  enum team_role: { member: 0, admin: 1 }

  # Associations
  belongs_to :team, optional: true
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'invited_by_id'

  # Business rule validations
  validates :team_id, absence: true, if: :direct?
  validates :team_id, presence: true, if: :invited?
end
```

#### Team Model (`app/models/team.rb`)
Multi-tenant team management with billing:

```ruby
class Team < ApplicationRecord
  include Pay::Billable  # Team-level Stripe billing

  # Associations
  belongs_to :admin, class_name: 'User'
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, dependent: :destroy

  # Plans and status
  enum plan: { starter: 0, pro: 1, enterprise: 2 }
  enum status: { active: 0, suspended: 1, cancelled: 2 }

  # URL-friendly slugs
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
end
```

#### Invitation Model (`app/models/invitation.rb`)
Secure token-based invitation system:

```ruby
class Invitation < ApplicationRecord
  belongs_to :team
  belongs_to :invited_by, class_name: 'User'

  # Security validations
  validates :email, uniqueness: { scope: :team_id }
  validate :email_not_in_users_table

  # Token generation
  before_validation :generate_secure_token, if: :new_record?
end
```

### Controllers Layer

The controller hierarchy enforces access control through inheritance:

```
ApplicationController
├── AuthenticatedController (requires login)
│   ├── AdminBaseController
│   │   ├── Admin::SuperBaseController
│   │   └── Admin::SiteBaseController
│   ├── TeamBaseController
│   │   └── Teams::AdminBaseController
│   └── UserBaseController
└── PublicController (no auth required)
```

### Service Objects

Business logic is encapsulated in service objects following the Single Responsibility Principle:

#### Teams::CreationService
Handles the complex team creation process:
- Validates super admin permissions
- Creates team with proper slug
- Assigns team admin
- Sets up Stripe billing
- Sends notifications

#### Users::StatusManagementService
Manages user status changes with:
- Authorization checks
- Audit logging
- Email notifications
- Forced logout for deactivated users

### Authorization (Pundit Policies)

Fine-grained authorization using Pundit policies:

```ruby
class TeamPolicy < ApplicationPolicy
  def show?
    super_admin? || site_admin? || team_member?
  end

  def update?
    super_admin? || team_admin?
  end

  def destroy?
    super_admin?
  end

  private

  def team_member?
    user.team_id == record.id
  end

  def team_admin?
    user.team_id == record.id && user.team_role == 'admin'
  end
end
```

## Database Schema

### Core Tables

#### users
- **Identity**: email, encrypted_password, first_name, last_name
- **Roles**: system_role, user_type, team_role
- **Status**: status, confirmed_at, locked_at
- **Associations**: team_id (for invited users only)
- **Billing**: stripe_customer_id (for direct users only)
- **Tracking**: sign_in_count, last_sign_in_at, last_activity_at

#### teams
- **Identity**: name, slug (unique URL identifier)
- **Management**: admin_id, created_by_id
- **Billing**: plan, stripe_customer_id, trial_ends_at
- **Limits**: max_members, status
- **Settings**: JSON configuration storage

#### invitations
- **Invitation**: team_id, email, role, invited_by_id
- **Security**: token (unique), expires_at
- **Status**: accepted_at

#### plans
- **Definition**: name, plan_type (individual/team)
- **Billing**: stripe_price_id, amount_cents, interval
- **Limits**: max_team_members, features (JSON)

### Database Constraints

The database enforces business rules through constraints:

```sql
-- Users table constraint
CONSTRAINT user_type_team_check CHECK (
  (user_type = 'direct' AND team_id IS NULL AND team_role IS NULL) OR
  (user_type = 'invited' AND team_id IS NOT NULL AND team_role IS NOT NULL)
)

-- Invitations table constraint
CONSTRAINT no_existing_user CHECK (
  NOT EXISTS (SELECT 1 FROM users WHERE users.email = invitations.email)
)
```

## Frontend Architecture

### Technology Stack
- **Import Maps**: Modern JavaScript without bundling complexity
- **Turbo**: SPA-like navigation without a frontend framework
- **Stimulus**: Modest JavaScript framework for HTML enhancement
- **Tailwind CSS**: Utility-first CSS framework
- **Rails Icons**: Consistent iconography throughout

### UI Organization
- **Layouts**: Separate layouts for admin, team, and user interfaces
- **Components**: Reusable Tailwind components for consistency
- **Forms**: Turbo-enhanced forms with inline validation
- **Navigation**: Context-aware navigation based on user type

## Security Architecture

### Authentication
- **Devise**: Industry-standard Rails authentication
- **Confirmation**: Email verification for all new accounts
- **Lockable**: Account locking after failed attempts
- **Trackable**: Login tracking and analytics

### Authorization
- **Pundit**: Policy-based authorization
- **Role checks**: Every action verified against user permissions
- **Team scoping**: Automatic data filtering by team context
- **Admin impersonation**: Secure user impersonation for support

### Security Measures
- **CSRF protection**: Rails default protection enabled
- **Strong parameters**: Whitelist all controller inputs
- **SQL injection prevention**: Parameterized queries throughout
- **XSS protection**: Automatic HTML escaping
- **Session security**: Secure session storage and rotation

## Billing & Payments

### Stripe Integration
- **Pay gem**: Simplified Stripe integration for Rails
- **Dual billing**: Separate flows for individuals and teams
- **Webhooks**: Automated subscription lifecycle management
- **Trial periods**: Configurable trials for new teams

### Subscription Management
- **Plan changes**: Upgrade/downgrade with proration
- **Payment methods**: Credit card management UI
- **Invoice history**: Downloadable invoices
- **Failed payments**: Automatic retry and notifications

## Background Jobs

### Solid Queue Integration
- **Email delivery**: Asynchronous email sending
- **Billing webhooks**: Stripe event processing
- **Analytics**: Background data aggregation
- **Cleanup tasks**: Expired invitation removal

## Analytics & Monitoring

### Ahoy Analytics
- **User tracking**: Page views and events
- **Team analytics**: Aggregated team usage metrics
- **Custom events**: Business-specific event tracking
- **Privacy-aware**: GDPR-compliant tracking

### Blazer Reporting
- **Admin dashboards**: SQL-based reporting
- **Scheduled reports**: Automated email reports
- **Custom queries**: Ad-hoc business intelligence

## Development Workflow

### Environment Setup
1. Ruby 3.2+ with Rails 8.0.2
2. SQLite for development (PostgreSQL ready)
3. Redis for caching and background jobs
4. Stripe CLI for webhook testing

### Testing Strategy
- **RSpec**: Comprehensive test suite
- **Factory Bot**: Test data generation
- **System tests**: Full integration testing
- **CI/CD ready**: GitHub Actions configuration

### Code Quality
- **Rubocop**: Ruby style enforcement
- **Brakeman**: Security vulnerability scanning
- **SimpleCov**: Code coverage tracking
- **Bullet**: N+1 query detection

## Deployment Architecture

### Production Stack
- **Kamal**: Modern deployment solution
- **Thruster**: HTTP/2 asset serving
- **Solid Cache**: Database-backed caching
- **Solid Cable**: Database-backed WebSockets

### Scaling Considerations
- **Database indexing**: Optimized query performance
- **Fragment caching**: View-level caching
- **CDN integration**: Asset delivery optimization
- **Background job queues**: Workload distribution

## Key Design Decisions

### 1. Dual-Track User System
**Decision**: Complete separation between individual and team users
**Rationale**: Simplifies billing, permissions, and user experience
**Trade-off**: Users cannot switch between modes

### 2. Database Constraints
**Decision**: Enforce business rules at the database level
**Rationale**: Data integrity regardless of application bugs
**Trade-off**: More complex migrations

### 3. Service Objects
**Decision**: Encapsulate complex operations in service classes
**Rationale**: Testability and single responsibility
**Trade-off**: Additional abstraction layer

### 4. Slug-Based Team URLs
**Decision**: Use slugs instead of IDs in URLs
**Rationale**: Better SEO and user experience
**Trade-off**: Additional slug management complexity

## Future Considerations

### Planned Enhancements
- API development for mobile apps
- OAuth2 provider for third-party integrations
- Advanced team permissions system
- White-label customization options

### Technical Debt
- Migrate from SQLite to PostgreSQL for production
- Implement comprehensive API versioning
- Add end-to-end encryption for sensitive data
- Enhance real-time features with ActionCable

## Conclusion

This Rails 8 SaaS application represents a production-ready, scalable architecture suitable for modern multi-tenant SaaS businesses. The careful separation of concerns, comprehensive security measures, and thoughtful design decisions create a maintainable codebase that can grow with business needs.

The architecture prioritizes:
- **Security**: Multiple layers of authentication and authorization
- **Scalability**: Service-oriented design and proper caching
- **Maintainability**: Clear separation of concerns and comprehensive testing
- **User Experience**: Modern frontend with Turbo/Stimulus
- **Business Flexibility**: Extensible design for future features