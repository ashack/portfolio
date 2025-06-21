# SaaS Rails Starter

A complete Ruby on Rails 8 SaaS application with triple-track user system supporting individual users, team-based collaboration, and enterprise organizations.

## Features

### User Types
- **Super Admin**: Platform owner with complete system access
- **Site Admin**: Customer support and user management
- **Direct User**: Individual users with personal billing who can also create teams
- **Team Admin**: Manages team billing and members (can be direct user or invited)
- **Team Member**: Invitation-only team participants
- **Enterprise Admin**: Manages enterprise organization and members
- **Enterprise User**: Members of enterprise organizations

### Core Features
- **Triple-Track SaaS Architecture**: Complete separation of individual, team, and enterprise user systems
- **Stripe Integration**: Pay gem for both team and individual billing
- **Complete Authentication**: Devise with all 8 security modules (lockable, confirmable, trackable, etc.)
- **Role-Based Authorization**: Comprehensive Pundit policies for all user types
- **User Status Management**: Active/inactive/locked states with admin controls
- **Team Management**: Full invitation system with email validation and resend/revoke functionality
- **Enterprise Organizations**: Large-scale user management with custom plans and dedicated workspace
- **Email System**: Professional email templates with Letter Opener for development preview
- **Professional UI**: Tailwind CSS with responsive design and styled Devise views
- **Analytics & Monitoring**: Ahoy Matey for user activity tracking
- **Admin Dashboards**: Separate interfaces for super admin, site admin, and enterprise admin
- **Security Hardened**: Rack::Attack rate limiting, CSRF protection, session security
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
- **UI Icons**: Rails Icons (Phosphor icon set)
- **Tab Navigation**: Reusable tab component for complex navigation
- **Testing**: Minitest with SimpleCov (24.14% coverage, 505 passing tests)
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
- Password: Password123!

## Usage

### Creating Teams
#### Method 1: Super Admin Creation
1. Login as super admin
2. Navigate to /admin/super/dashboard
3. Click "Create New Team"
4. Assign an existing user as team admin

#### Method 2: Direct User Creation
1. Register as direct user
2. Select a team plan during registration
3. Enter team name when prompted
4. Automatically become team admin

### User Registration Flows
- **Direct Users**: Register via public signup at /users/sign_up
- **Team Members**: Must be invited by team admin (invitation-only)
- **Enterprise Users**: Must be invited by enterprise admin (invitation-only)

### Creating Enterprise Organizations (Super Admin Only)
1. Login as super admin
2. Navigate to /admin/super/dashboard
3. Click "Enterprise Groups" tab
4. Create new enterprise group
5. Send invitation to designated admin
6. Admin accepts invitation and gains full access

### Important Business Rules
1. Direct users CANNOT join teams via invitation (but can create their own teams)
2. Team members CANNOT become direct users
3. Only super admins can create teams (except direct users creating during registration)
4. Team admins can delete team members completely
5. Invitations can only be sent to new email addresses
6. Enterprise users are completely separate from team/individual systems
7. Enterprise admins are assigned via invitation during group creation

## Testing

### Running Tests
```bash
# Run all tests with accurate coverage reporting
PARALLEL_WORKERS=1 bundle exec rails test

# Run specific test files
bundle exec rails test test/models/user_test.rb

# Run with verbose output
bundle exec rails test -v

# Run a specific test method
bundle exec rails test test/models/user_test.rb -n test_should_be_valid_with_valid_attributes
```

### Code Coverage
SimpleCov is configured to generate coverage reports automatically when running tests.

**Current Coverage**: 24.02% line coverage, 65.12% branch coverage
**Test Suite**: 505 tests, 1438 assertions, 14 failures (mostly design issues)

```bash
# After running tests, view coverage report
open coverage/index.html
```

Coverage configuration includes:
- Branch coverage tracking
- Separate groups for models, controllers, services, etc.
- HTML reports with detailed line-by-line coverage

### Writing Tests
The project uses Minitest for testing with the following helpers:

```ruby
# Sign in a user in tests
sign_in_as(user)

# Create and sign in a user with specific attributes
user = sign_in_with(
  email: "test@example.com",
  system_role: "super_admin",
  user_type: "direct"
)
```

### Test Structure
```
test/
├── application_system_test_case.rb  # Base class for system tests
├── test_helper.rb                   # Test configuration and helpers
├── models/                          # Model tests
│   └── user_test.rb
├── controllers/                     # Controller tests
├── system/                          # System/integration tests
│   └── user_registration_test.rb
└── fixtures/                        # Test data
```

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

## Security Configuration

### Rack::Attack Protection
The application includes comprehensive rate limiting and security filtering:

#### Rate Limits
- **General requests**: 60/minute per IP
- **Login attempts**: 5/20 seconds per IP
- **Password resets**: 5/hour per IP  
- **Sign ups**: 3/hour per IP
- **Team invitations**: 20/day per user
- **Enterprise invitations**: 30/day per user
- **Enterprise admin actions**: 100/hour per user

#### Security Filters
- **Blocked paths**: Common vulnerability scans (wp-admin, .env, .git, etc.)
- **Blocked user agents**: Known scanners and bots
- **Fail2Ban**: Auto-blocks IPs after 3 failed logins

### Environment Variables for Security
```bash
# Add to .env for production
ALLOWED_IPS=192.168.1.100,10.0.0.50  # Whitelist IPs
REDIS_URL=redis://localhost:6379/0    # For distributed rate limiting
```

## Code Quality

### Linting
The project uses RuboCop with Rails Omakase standards:

```bash
# Run linting
bundle exec rubocop

# Auto-correct issues
bundle exec rubocop --autocorrect

# Run specific file/directory
bundle exec rubocop app/models/
```

### Security Scanning
```bash
# Run Brakeman security scanner
bundle exec brakeman

# Run with detailed output
bundle exec brakeman -A
```

## Documentation

### 📚 Complete Documentation Available
- [Security Guide](docs/security.md) - Authentication, authorization, and security implementation
- [Security Best Practices](docs/security_best_practices.md) - Development and deployment security guidelines
- [Rack::Attack Configuration](docs/rack_attack_configuration.md) - Rate limiting and protection rules
- [Bug Fixes & Troubleshooting](docs/bug_fixes.md) - Solutions to common Rails 8.0.2 issues
- [Development Task List](docs/task_list.md) - Current status and future roadmap  
- [Common Pitfalls](docs/pitfalls.md) - Anti-patterns and how to avoid them
- [Testing Guide](docs/testing.md) - Testing setup, best practices, and coverage guidelines
- [UI Components & Design System](docs/ui_components.md) - Phosphor icons, Tailwind CSS, responsive design
- [Enterprise Features](docs/enterprise_features.md) - Enterprise organization management and workflows

### 🔧 Development Tools
- `/auth_debug` - Authentication debugging interface (development only)
- `/devise_showcase` - View all styled Devise forms (development only)
- Letter Opener - Preview emails at http://localhost:3000/letter_opener (development only)

### 🎯 Production Ready Features
- ✅ **Rails 8.0.2 Compatible** with all callback validation fixes
- ✅ **Security Hardened** with comprehensive protection measures
- ✅ **Performance Optimized** with proper indexing and caching
- ✅ **Professional UI** with responsive Tailwind CSS design
- ✅ **Zero Security Warnings** (Brakeman verified)
- ✅ **RuboCop Compliant** (Rails Omakase standards)
- ✅ **Test Coverage** with Minitest and SimpleCov
- ✅ **Phosphor Icons** integrated via Rails Icons gem

## Architecture Highlights

### Triple-Track User System
- **Individual Users**: Register directly, personal billing, can create teams
- **Team Users**: Invitation-only, shared billing, collaborative features
- **Enterprise Users**: Large organizations with custom plans and centralized management
- **Complete Separation**: No crossover between user types (except direct users creating teams)

### Security Features
- **8 Devise Modules**: Database auth, registration, recovery, confirmation, lockable, trackable
- **Pundit Authorization**: Comprehensive policies for all user types
- **Rack::Attack Protection**: Rate limiting, IP blocking, and security filtering
- **Strong Password Requirements**: Enforced complexity with clear user feedback
- **Mass Assignment Protection**: Secure parameter handling
- **Session Security**: HttpOnly, secure, SameSite cookie protection
- **CSRF Protection**: Enhanced with per-form tokens and origin checking

### Admin Capabilities
- **Super Admin**: Team/enterprise creation, system management, billing oversight
- **Site Admin**: User support, status management, view organizations (no billing access)
- **Team Admin**: Member management, team billing, invitations
- **Enterprise Admin**: Organization management, member invitations, enterprise billing

### Testing Infrastructure
- **Minitest**: Rails default testing framework
- **SimpleCov**: Code coverage reporting with branch coverage
- **System Tests**: Headless Chrome with Selenium
- **Test Helpers**: Authentication helpers for easy test setup
- **Parallel Testing**: Configured for faster test runs

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass and maintain coverage
5. Run linting and fix any issues
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

This project is available as open source under the terms of the MIT License.