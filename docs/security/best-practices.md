# Security Best Practices Guide

## Overview

This guide provides security best practices for developing and deploying the SaaS Rails application. Following these practices will help maintain a secure application environment.

## Development Security

### 1. Environment Variables
```bash
# Never commit sensitive data
# ❌ BAD: Hardcoded secrets
STRIPE_SECRET_KEY = "sk_test_123456789"

# ✅ GOOD: Use environment variables
STRIPE_SECRET_KEY = ENV['STRIPE_SECRET_KEY']
```

### 2. Secure Coding Practices

#### Input Validation
```ruby
# ❌ BAD: No validation
def update_email
  user.update!(email: params[:email])
end

# ✅ GOOD: Validate and sanitize
def update_email
  email = params[:email].strip.downcase
  if email.match?(URI::MailTo::EMAIL_REGEXP)
    user.update!(email: email)
  else
    render_error("Invalid email format")
  end
end
```

#### SQL Injection Prevention
```ruby
# ❌ BAD: Direct interpolation
User.where("email = '#{params[:email]}'")

# ✅ GOOD: Parameterized queries
User.where(email: params[:email])
User.where("email = ?", params[:email])
```

#### Mass Assignment Protection
```ruby
# ❌ BAD: Permit all parameters
params.require(:user).permit!

# ✅ GOOD: Explicitly permit parameters
params.require(:user).permit(:first_name, :last_name, :email)
```

### 3. Authentication & Authorization

#### Always Check Authorization
```ruby
# ❌ BAD: No authorization check
def admin_dashboard
  @users = User.all
end

# ✅ GOOD: Verify authorization
def admin_dashboard
  authorize :admin, :dashboard?
  @users = User.all
end
```

#### Secure Password Requirements
```ruby
# Enforce in User model
validates :password, 
  length: { minimum: 12 },
  format: { 
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/,
    message: "must include uppercase, lowercase, number and special character"
  }
```

### 4. Session Security

#### Secure Session Configuration
```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_app_session',
  secure: Rails.env.production?,  # HTTPS only in production
  httponly: true,                 # Prevent JS access
  same_site: :lax,               # CSRF protection
  expire_after: 30.minutes       # Reasonable timeout
```

#### Session Fixation Prevention
```ruby
# After successful login
def create
  if user.valid_password?(params[:password])
    reset_session  # Prevent session fixation
    sign_in(user)
  end
end
```

## Production Deployment Security

### 1. SSL/TLS Configuration
```ruby
# config/environments/production.rb
config.force_ssl = true
config.ssl_options = { 
  hsts: { 
    subdomains: true, 
    preload: true,
    expires: 1.year 
  } 
}
```

### 2. Security Headers
```ruby
# config/application.rb
config.middleware.use Rack::Protection
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://yourdomain.com'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```

### 3. Content Security Policy
```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline
  end
end
```

## Database Security

### 1. Encrypted Credentials
```bash
# Edit credentials
EDITOR="vim" rails credentials:edit

# Access in code
Rails.application.credentials.stripe[:secret_key]
```

### 2. Database Backups
```bash
# Automated encrypted backups
pg_dump -U postgres -h localhost dbname | \
  openssl enc -aes-256-cbc -salt -out backup.sql.enc
```

### 3. Query Logging
```ruby
# Mask sensitive data in logs
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.formatter = proc do |severity, time, progname, msg|
  msg.gsub!(/password=>'[^']*'/, "password=>'[FILTERED]'")
  "#{time} #{severity}: #{msg}\n"
end
```

## Monitoring & Incident Response

### 1. Security Event Logging
```ruby
# Log all security events
class SecurityLogger
  def self.log(event_type, details)
    Rails.logger.tagged('SECURITY') do
      Rails.logger.warn("#{event_type}: #{details.to_json}")
    end
  end
end

# Usage
SecurityLogger.log('failed_login', { 
  ip: request.remote_ip, 
  email: params[:email] 
})
```

### 2. Automated Security Alerts
```ruby
# Send alerts for suspicious activity
class SecurityAlert
  def self.notify(event)
    if critical_event?(event)
      AdminMailer.security_alert(event).deliver_later
      # Optional: Send to Slack, PagerDuty, etc.
    end
  end
  
  private
  
  def self.critical_event?(event)
    %w[multiple_failed_logins privilege_escalation 
       suspicious_activity].include?(event[:type])
  end
end
```

### 3. Regular Security Audits
```bash
# Run security checks
bundle audit check
brakeman -A
rails_best_practices

# Check for vulnerable dependencies
yarn audit
npm audit
```

## API Security

### 1. API Authentication
```ruby
# Use tokens for API authentication
class ApiController < ApplicationController
  before_action :authenticate_api_token!
  
  private
  
  def authenticate_api_token!
    token = request.headers['Authorization']&.split(' ')&.last
    @current_api_user = User.find_by_api_token(token)
    
    unless @current_api_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
```

### 2. API Rate Limiting
```ruby
# Already configured in Rack::Attack
throttle('api/user', limit: 100, period: 1.minute) do |req|
  if req.path.start_with?('/api/')
    req.env['warden'].user&.id if req.env['warden'].user
  end
end
```

## Security Checklist

### Pre-Deployment
- [ ] All environment variables configured
- [ ] SSL certificates installed
- [ ] Database credentials secured
- [ ] Admin accounts use strong passwords
- [ ] Rate limiting configured
- [ ] Security headers enabled
- [ ] CORS properly configured
- [ ] CSP policy defined

### Post-Deployment
- [ ] Monitor security logs
- [ ] Set up automated backups
- [ ] Configure security alerts
- [ ] Schedule security audits
- [ ] Plan incident response
- [ ] Document security procedures
- [ ] Train team on security practices

## Common Security Mistakes to Avoid

### 1. Exposing Sensitive Information
```ruby
# ❌ BAD: Exposing internal info in errors
rescue_from StandardError do |e|
  render json: { error: e.message, backtrace: e.backtrace }
end

# ✅ GOOD: Generic error messages
rescue_from StandardError do |e|
  Rails.logger.error "Error: #{e.message}\n#{e.backtrace.join("\n")}"
  render json: { error: 'An error occurred' }, status: :internal_server_error
end
```

### 2. Insecure Direct Object References
```ruby
# ❌ BAD: Direct access without authorization
def show
  @document = Document.find(params[:id])
end

# ✅ GOOD: Scope to authorized resources
def show
  @document = current_user.documents.find(params[:id])
end
```

### 3. Weak Cryptography
```ruby
# ❌ BAD: MD5 or SHA1
Digest::MD5.hexdigest(password)

# ✅ GOOD: Use bcrypt (via Devise)
user.valid_password?(password)
```

## Security Resources

### Tools
- **Brakeman**: Static analysis security scanner
- **bundler-audit**: Checks for vulnerable gem versions
- **OWASP ZAP**: Web application security scanner
- **RuboCop**: Code analysis with security cops

### References
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Ruby Security Advisory Database](https://rubysec.com/)

### Regular Updates
```bash
# Keep dependencies updated
bundle update --conservative
yarn upgrade-interactive

# Check for security updates
bundle audit update
```

## Incident Response Plan

### 1. Detection
- Monitor logs for anomalies
- Set up alerts for failed logins
- Track unusual API usage patterns

### 2. Response
1. Isolate affected systems
2. Preserve evidence (logs, database snapshots)
3. Patch vulnerabilities
4. Reset affected credentials
5. Notify affected users if required

### 3. Recovery
1. Restore from clean backups
2. Apply all security patches
3. Enhance monitoring
4. Document lessons learned

---

**Remember**: Security is not a one-time task but an ongoing process. Stay informed about new vulnerabilities and best practices.