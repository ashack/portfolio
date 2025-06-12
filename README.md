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
- Stripe integration for billing (teams and individuals)
- Invitation system for team members
- Role-based authorization with Pundit
- User status management (active/inactive/locked)
- Separate dashboards for each user type
- Analytics and monitoring

## Setup Instructions

### Prerequisites
- Ruby 3.2.5
- Rails 8.0.2
- SQLite3
- Stripe account

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

## License

This project is available as open source under the terms of the MIT License.
