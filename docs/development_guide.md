# Rails SaaS Starter - Development Guide

*Last Updated: January 2025*

This guide covers development workflows, best practices, deployment procedures, and success criteria for the Rails SaaS Starter application.

## Table of Contents

1. [Development Workflow](#development-workflow)
2. [Adding New Features](#adding-new-features)
3. [Bug Fix Process](#bug-fix-process)
4. [Code Review Process](#code-review-process)
5. [Testing Strategy](#testing-strategy)
6. [Deployment Roadmap](#deployment-roadmap)
7. [Success Criteria](#success-criteria)
8. [Development Tools](#development-tools)

## Development Workflow

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd saas_ror_starter
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Database setup**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Environment configuration**
   - Copy `.env.example` to `.env`
   - Configure Stripe keys
   - Set up mail settings

### Daily Development Process

1. **Update your branch**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/your-feature-name
   ```

2. **Run tests before starting**
   ```bash
   bundle exec rails test
   ```

3. **Start development server**
   ```bash
   bin/dev
   ```

4. **Make your changes following the guidelines below**

5. **Commit with descriptive messages**
   ```bash
   git add .
   git commit -m "feat: add enterprise dashboard analytics"
   ```

## Adding New Features

### 1. Planning Phase
- **Document requirements** in the task list or a new issue
- **Design the data model** and relationships
- **Create mockups or wireframes** for UI changes
- **Identify security implications**
- **Plan the testing strategy**

### 2. Authorization Setup
- **Create or update Pundit policies**
  ```ruby
  # app/policies/feature_policy.rb
  class FeaturePolicy < ApplicationPolicy
    def index?
      user.present?
    end
  end
  ```
- **Test authorization in isolation**
- **Document permission requirements**

### 3. Implementation Steps
1. **Create database migrations**
   ```bash
   rails generate migration AddFeatureToUsers feature:boolean
   ```

2. **Update models with validations**
   ```ruby
   validates :feature, inclusion: { in: [true, false] }
   ```

3. **Create service objects for complex logic**
   ```ruby
   # app/services/features/activation_service.rb
   class Features::ActivationService < ApplicationService
     # Implementation
   end
   ```

4. **Build controllers with proper error handling**
   ```ruby
   def create
     result = Features::ActivationService.call(params)
     
     if result.success?
       redirect_to feature_path(result.data), notice: "Feature activated"
     else
       render :new, alert: result.error
     end
   end
   ```

5. **Create views following existing patterns**
   - Use ViewComponents for reusable UI
   - Follow Tailwind CSS conventions
   - Ensure mobile responsiveness

### 4. Testing Requirements
- **Write tests before implementation** (TDD approach)
- **Cover all new code paths**
- **Test authorization scenarios**
- **Add system tests for critical flows**

### 5. Security Review
- **Review for SQL injection vulnerabilities**
- **Check for XSS possibilities**
- **Ensure proper parameter filtering**
- **Validate all user inputs**
- **Test rate limiting if applicable**

### 6. Documentation Updates
- **Update relevant documentation files**
- **Add inline code comments for complex logic**
- **Update API documentation if applicable**
- **Add to changelog/recent updates**

## Bug Fix Process

### 1. Reproduction
- **Create a minimal test case** that reproduces the issue
- **Document steps to reproduce**
- **Identify affected versions/environments**
- **Check if it's a regression**

### 2. Root Cause Analysis
- **Check application logs**
  ```bash
  tail -f log/development.log
  ```
- **Use Rails console for debugging**
  ```bash
  rails console
  ```
- **Review recent changes** that might have caused the issue
- **Use git bisect if needed** to find the breaking commit

### 3. Solution Implementation
- **Write a failing test** that exposes the bug
- **Implement the minimal fix** needed
- **Ensure the test passes**
- **Check for side effects** on related functionality

### 4. Verification
- **Test in multiple scenarios**:
  - Different user types (admin, team member, etc.)
  - Various data states
  - Edge cases
- **Test in staging environment**
- **Get peer review**

### 5. Documentation
- **Update troubleshooting guides**
- **Document the fix in commit message**
- **Add to bug fixes documentation if significant**
- **Create or update tests to prevent regression**

## Code Review Process

### Submitting for Review

1. **Self-review your changes first**
2. **Ensure all tests pass**
3. **Run linting tools**
   ```bash
   bundle exec rubocop
   ```
4. **Create a descriptive pull request**
5. **Link to related issues/tasks**

### Code Review Checklist

#### Security
- [ ] No SQL injection vulnerabilities
- [ ] Proper authorization checks with Pundit
- [ ] Strong parameters used correctly
- [ ] No sensitive data in logs
- [ ] CSRF protection maintained

#### Code Quality
- [ ] Follows Rails conventions
- [ ] No code duplication (DRY principle)
- [ ] Clear variable and method names
- [ ] Appropriate use of service objects
- [ ] Proper error handling

#### Testing
- [ ] All new code has tests
- [ ] Tests are meaningful and comprehensive
- [ ] Edge cases covered
- [ ] No flaky tests introduced

#### Performance
- [ ] No N+1 queries introduced
- [ ] Appropriate database indexes added
- [ ] Caching used where beneficial
- [ ] Background jobs for heavy operations

#### Documentation
- [ ] Code is self-documenting
- [ ] Complex logic has comments
- [ ] API changes documented
- [ ] User-facing changes noted

## Testing Strategy

### Test Pyramid

1. **Unit Tests** (70%)
   - Model validations and methods
   - Service objects
   - Helper methods
   - Background jobs

2. **Integration Tests** (20%)
   - Controller actions
   - API endpoints
   - Complex workflows

3. **System Tests** (10%)
   - Critical user journeys
   - Payment flows
   - Authentication flows

### Running Tests

```bash
# Run all tests
bundle exec rails test

# Run specific test file
bundle exec rails test test/models/user_test.rb

# Run with coverage report
bundle exec rails test
open coverage/index.html

# Run tests in parallel (if configured)
bundle exec rails test:parallel
```

### Writing Effective Tests

```ruby
# Use descriptive test names
test "user cannot access team resources without membership" do
  # Arrange
  user = create(:user)
  team = create(:team)
  
  # Act & Assert
  assert_raises(Pundit::NotAuthorizedError) do
    TeamPolicy.new(user, team).show?
  end
end

# Test edge cases
test "invitation expires after 7 days" do
  invitation = create(:invitation)
  travel_to 8.days.from_now
  
  assert invitation.expired?
end
```

## Deployment Roadmap

### Phase 1: Production Setup (1-2 weeks)

#### Environment Configuration
- [ ] Set up production database (PostgreSQL)
- [ ] Configure Redis for caching and background jobs
- [ ] Set up email service (SendGrid/Postmark)
- [ ] Configure SSL certificates
- [ ] Set up CDN for assets
- [ ] Configure error tracking (Sentry/Rollbar)

#### Infrastructure Setup
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db_name

# Redis
REDIS_URL=redis://host:6379/0

# Email
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_api_key

# Application
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key
```

#### Testing & QA
- [ ] Run full test suite
- [ ] Perform security audit
- [ ] Load testing with realistic data
- [ ] Test payment flows in Stripe test mode
- [ ] Verify email delivery
- [ ] Test error handling and monitoring

### Phase 2: Launch Preparation (1 week)

#### Monitoring Setup
- [ ] Configure application performance monitoring (APM)
- [ ] Set up uptime monitoring
- [ ] Configure log aggregation
- [ ] Set up alerting rules
- [ ] Create operational dashboards

#### Documentation Finalization
- [ ] Complete user guides
- [ ] Finalize admin documentation
- [ ] API documentation (if applicable)
- [ ] Operational runbooks
- [ ] Disaster recovery procedures

#### Pre-launch Checklist
- [ ] Database backups configured
- [ ] Staging environment mirrors production
- [ ] Rollback procedures documented
- [ ] Team trained on deployment process
- [ ] Support channels established

### Phase 3: Post-Launch (Ongoing)

#### Feature Enhancements
- Monitor user feedback channels
- Prioritize improvements based on usage
- A/B test new features
- Gradual rollout for major changes

#### Performance Optimization
- Regular performance audits
- Database query optimization
- Caching strategy refinement
- CDN optimization

#### Security Updates
- Regular dependency updates
- Security patch deployment process
- Periodic security audits
- Penetration testing schedule

## Success Criteria

### Technical Goals

#### Performance
- [ ] 99.9% uptime (allows ~8.76 hours downtime/year)
- [ ] <200ms average response time
- [ ] <3s page load time (95th percentile)
- [ ] Support 10,000+ concurrent users

#### Quality
- [ ] Zero critical security vulnerabilities
- [ ] 90%+ test coverage
- [ ] <1% error rate in production
- [ ] All features work across modern browsers

#### Scalability
- [ ] Horizontal scaling capability
- [ ] Database can handle 1M+ records
- [ ] Background job processing scales with load
- [ ] Caching reduces database load by 50%+

### Business Goals

#### User Experience
- [ ] Smooth onboarding in <5 minutes
- [ ] Intuitive navigation (no training required)
- [ ] Mobile-responsive design
- [ ] Accessible to users with disabilities

#### Operations
- [ ] Clear pricing and billing
- [ ] Self-service team management
- [ ] Comprehensive admin tools
- [ ] Detailed analytics and reporting

#### Growth
- [ ] Scalable architecture for feature additions
- [ ] API-ready for integrations
- [ ] Multi-language support capability
- [ ] White-label potential

## Development Tools

### Essential Commands

```bash
# Rails console
rails console

# Database console
rails dbconsole

# View routes
rails routes | grep user

# Clear cache
rails dev:cache

# Run specific migration
rails db:migrate:up VERSION=20240101120000

# Rollback migration
rails db:rollback STEP=1

# Background job processing (development)
bin/jobs

# Asset compilation
rails assets:precompile

# Check for security vulnerabilities
bundle audit

# Update dependencies safely
bundle update --conservative
```

### Debugging Tips

1. **Use `byebug` for debugging**
   ```ruby
   def complex_method
     byebug  # Execution stops here
     # Your code
   end
   ```

2. **Rails logger for tracking**
   ```ruby
   Rails.logger.info "Processing user: #{user.id}"
   Rails.logger.error "Failed to process: #{e.message}"
   ```

3. **SQL query logging**
   ```ruby
   ActiveRecord::Base.logger = Logger.new(STDOUT)
   ```

4. **Performance profiling**
   ```ruby
   # In development.rb
   config.middleware.use Rack::MiniProfiler
   ```

### Git Workflow

```bash
# Feature branch
git checkout -b feature/amazing-feature

# Regular commits
git add -p  # Interactive staging
git commit -m "feat: add user preferences"

# Keep branch updated
git fetch origin
git rebase origin/main

# Push for review
git push origin feature/amazing-feature
```

## Additional Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [Ruby Style Guide](https://rubystyle.guide/)
- [Pundit Documentation](https://github.com/varvet/pundit)
- [Stripe API Reference](https://stripe.com/docs/api)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

---

**Remember**: Good code is written for humans to read, not just for machines to execute. Always prioritize clarity and maintainability.