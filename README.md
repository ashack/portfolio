# SaaS Rails Starter

A complete Ruby on Rails 8 SaaS application with dual-track user system supporting both team-based and individual users.

## Features

### User Types
- **Super Admin**: Platform owner with complete system access
- **Site Admin**: Customer support and user management
- **Direct User**: Individual users with personal billing
- **Team Admin**: Manages team billing and members
- **Team Member**: Invitation-only team participants

### Core Features
- **Dual-Track SaaS Architecture**: Complete separation of team and individual user systems
- **Stripe Integration**: Pay gem for both team and individual billing
- **Complete Authentication**: Devise with all 8 security modules (lockable, confirmable, trackable, etc.)
- **Role-Based Authorization**: Comprehensive Pundit policies for all user types
- **User Status Management**: Active/inactive/locked states with admin controls
- **Team Management**: Full invitation system with email validation and resend/revoke functionality
- **Email System**: Professional email templates with Letter Opener for development preview
- **Professional UI**: Tailwind CSS with responsive design and styled Devise views
- **Analytics & Monitoring**: Ahoy Matey for user activity tracking
- **Admin Dashboards**: Separate interfaces for super admin and site admin
- **Security Hardened**: Mass assignment protection, CSRF, session security
- **Rails 8.0.2 Ready**: Full compatibility with latest Rails and Turbo features

## Setup Instructions

### Prerequisites
- Ruby 3.2.5
- Rails 8.0.2
- SQLite3 (development) / PostgreSQL (production)
- Node.js and npm (for Tailwind CSS)
- Stripe account

### Technology Stack
- **Backend**: Rails 8.0.2, Ruby 3.2.5
- **Database**: SQLite3 (dev), PostgreSQL (production)  
- **Frontend**: Tailwind CSS, Stimulus, Turbo
- **Authentication**: Devise with 8 security modules
- **Authorization**: Pundit policies
- **Payments**: Stripe via Pay gem
- **Analytics**: Ahoy Matey
- **UI Icons**: Rails Icons
- **Session Store**: Secure cookie store with httponly/secure flags

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd saas_ror_starter
```

2. Install dependencies
```bash
bundle install
```

3. Setup database
```bash
rails db:create
rails db:migrate
rails db:seed
```

4. Configure environment variables
```bash
# Create .env file with:
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret
```

5. Start the server
```bash
bin/dev
```

### Default Credentials

After running seeds, you'll have a super admin account:
- Email: super@admin.com
- Password: password123

## Usage

### Creating Teams (Super Admin Only)
1. Login as super admin
2. Navigate to /admin/super/dashboard
3. Click "Create New Team"
4. Assign an existing user as team admin

### User Registration Flows
- **Direct Users**: Register via public signup at /users/sign_up
- **Team Members**: Must be invited by team admin (invitation-only)

### Important Business Rules
1. Direct users CANNOT join teams
2. Team members CANNOT become direct users
3. Only super admins can create teams
4. Team admins can delete team members completely
5. Invitations can only be sent to new email addresses

## Deployment

### Docker
```bash
docker build -t saas_app .
docker run -p 3000:3000 -e RAILS_MASTER_KEY=<your-key> saas_app
```

### Kamal
```bash
kamal setup
kamal deploy
```

## Testing

```bash
rspec
```

## Documentation

### 📚 Complete Documentation Available
- [Security Guide](docs/security.md) - Authentication, authorization, and security best practices
- [Bug Fixes & Troubleshooting](docs/bug_fixes.md) - Solutions to common Rails 8.0.2 issues
- [Development Task List](docs/task_list.md) - Current status and future roadmap  
- [Common Pitfalls](docs/pitfalls.md) - Anti-patterns and how to avoid them

### 🔧 Development Tools
- `/auth_debug` - Authentication debugging interface (development only)
- `/devise_showcase` - View all styled Devise forms (development only)
- `rails auth:test` - Test authentication flow via rake task

### 🎯 Production Ready Features
- ✅ **Rails 8.0.2 Compatible** with all callback validation fixes
- ✅ **Security Hardened** with comprehensive protection measures
- ✅ **Performance Optimized** with proper indexing and caching
- ✅ **Professional UI** with responsive Tailwind CSS design
- ✅ **Zero Security Warnings** (Brakeman verified)
- ✅ **RuboCop Compliant** (Rails Omakase standards)

## Architecture Highlights

### Dual-Track User System
- **Individual Users**: Register directly, personal billing, isolated features
- **Team Users**: Invitation-only, shared billing, collaborative features
- **Complete Separation**: No crossover between user types

### Security Features
- **8 Devise Modules**: Database auth, registration, recovery, confirmation, lockable, trackable
- **Pundit Authorization**: Comprehensive policies for all user types
- **Mass Assignment Protection**: Secure parameter handling
- **Session Security**: HttpOnly, secure, SameSite cookie protection

### Admin Capabilities
- **Super Admin**: Team creation, system management, billing oversight
- **Site Admin**: User support, status management (no billing access)
- **Team Admin**: Member management, team billing, invitations

## License

This project is available as open source under the terms of the MIT License.
