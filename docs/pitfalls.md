# Common Pitfalls & Anti-Patterns

## Rails 8.0.2 Specific Pitfalls

### 1. Callback Validation Errors

**❌ What Goes Wrong**:
```ruby
# Rails 8.0.2 validates ALL callback actions must exist
after_action :verify_authorized, except: [:index]  # Will fail if no index action
```

**⚠️ The Trap**: Even actions in `:except` must exist in the controller

**✅ Solution**: Use configuration-level fix
```ruby
# config/environments/development.rb & production.rb
config.action_controller.raise_on_missing_callback_actions = false
```

**🔍 Why This Happens**: Rails 8.0.2 has stricter callback validation than previous versions

### 2. Turbo Method Compatibility

**❌ What Goes Wrong**:
```erb
<!-- This won't work with Turbo -->
<%= link_to "Delete", record_path, method: :delete %>
```

**⚠️ The Trap**: Rails UJS patterns don't work with Turbo

**✅ Solution**: Use Turbo data attributes
```erb
<%= link_to "Delete", record_path, data: { "turbo-method": :delete } %>
```

**🔍 Why This Happens**: Rails 8+ uses Turbo instead of UJS for handling non-GET requests

### 3. Route Parameter Conflicts with to_param

**❌ What Goes Wrong**:
```ruby
# Model with custom to_param for public URLs
class Invitation < ApplicationRecord
  def to_param
    token  # For public invitation acceptance
  end
end

# But admin routes expect numeric IDs
resend_invitation_path(invitation)  # Generates /invitations/token123/resend
```

**⚠️ The Trap**: `to_param` affects ALL route generation, not just intended routes

**✅ Solution**: Explicitly use ID for admin routes
```erb
<!-- Explicit ID bypasses to_param -->
<%= button_to "Resend", resend_path(id: invitation.id), method: :post %>
```

**🔍 Why This Happens**: Rails uses `to_param` for all route parameter generation

### 4. Button vs Link for Non-GET Requests

**❌ What Goes Wrong**:
```erb
<!-- Unreliable with Rails 8.0.2 + Turbo -->
<%= link_to "Delete", record_path, data: { "turbo-method": :delete } %>
```

**⚠️ The Trap**: Even with correct Turbo syntax, links can be unreliable for non-GET requests

**✅ Solution**: Use button_to for reliable method handling
```erb
<%= button_to "Delete", record_path, method: :delete,
    class: "bg-transparent border-none underline cursor-pointer",
    form_class: "inline" %>
```

**🔍 Why This Happens**: `button_to` creates actual forms which handle HTTP methods more reliably

### 5. Missing Model Methods Referenced in Controllers

**❌ What Goes Wrong**:
```ruby
# Controller calling non-existent method
if @invitation.pending? && !@invitation.expired?
  # NoMethodError: undefined method 'pending?' for #<Invitation>
end
```

**⚠️ The Trap**: Controllers referencing methods that don't exist on models

**✅ Solution**: Ensure all referenced methods exist
```ruby
# app/models/invitation.rb
def pending?
  !accepted?
end
```

**🔍 Why This Happens**: Easy to overlook method definitions when writing controller logic

### 6. Confirmation Dialog Compatibility

**❌ What Goes Wrong**:
```erb
<!-- Rails UJS confirmation -->
<%= button_to "Delete", path, data: { confirm: "Are you sure?" } %>
```

**⚠️ The Trap**: `confirm` attribute doesn't work with Turbo

**✅ Solution**: Use Turbo-compatible confirmation
```erb
<%= button_to "Delete", path, data: { turbo_confirm: "Are you sure?" } %>
```

**🔍 Why This Happens**: Turbo uses different attribute names than UJS

## Authentication Pitfalls

### 7. Devise Callback Interference

**❌ What Goes Wrong**:
```ruby
class ApplicationController
  before_action :authenticate_user!
  before_action :check_user_status  # Runs during Devise authentication!
end
```

**⚠️ The Trap**: Application callbacks interfere with Devise's authentication flow

**✅ Solution**: Skip for Devise controllers
```ruby
before_action :check_user_status, unless: :devise_controller?
```

**🔍 Why This Happens**: Devise manages its own authentication state during sign-in/out

### 4. Third-Party Gem Integration

**❌ What Goes Wrong**:
```ruby
# Ahoy analytics trying to access current_user
def authenticate(data)
  data[:user_id] = controller.current_user.id  # controller can be nil!
end
```

**⚠️ The Trap**: Assuming controller context always exists

**✅ Solution**: Defensive programming
```ruby
def authenticate(data)
  if controller && controller.respond_to?(:current_user) && controller.current_user
    data[:user_id] = controller.current_user.id
  end
end
```

**🔍 Why This Happens**: Third-party gems may execute at various request lifecycle points

## Security Pitfalls

### 5. Mass Assignment Vulnerabilities

**❌ What Goes Wrong**:
```ruby
# Dangerous parameter permissions
params.require(:invitation).permit(:email, :role)  # User can assign admin role!
```

**⚠️ The Trap**: Trusting user input for sensitive parameters

**✅ Solution**: Validate and authorize parameter values
```ruby
def invitation_params
  base_params = params.require(:invitation).permit(:email)
  allowed_role = determine_allowed_role(params[:invitation][:role])
  base_params.merge(role: allowed_role)
end
```

**🔍 Why This Happens**: Rails permits parameters but doesn't validate their values

### 6. Authorization Logic Gaps

**❌ What Goes Wrong**:
```ruby
# Incomplete authorization logic
def team_admin?
  current_user.team_role == 'admin'  # But what if user has no team?
end
```

**⚠️ The Trap**: Forgetting edge cases in authorization logic

**✅ Solution**: Comprehensive checks
```ruby
def team_admin?
  current_user&.invited? && 
  current_user&.team_id == @team&.id && 
  current_user&.team_role == 'admin'
end
```

**🔍 Why This Happens**: Authorization logic often misses null/edge cases

## Database Design Pitfalls

### 7. Missing Database Constraints

**❌ What Goes Wrong**:
```ruby
# Only model validations, no database constraints
class User < ApplicationRecord
  validates :user_type, inclusion: { in: %w[direct invited] }
  # What if someone bypasses Rails and inserts directly into DB?
end
```

**⚠️ The Trap**: Relying only on application-level validations

**✅ Solution**: Database-level constraints
```sql
CONSTRAINT user_type_team_check CHECK (
  (user_type = 'direct' AND team_id IS NULL) OR
  (user_type = 'invited' AND team_id IS NOT NULL)
)
```

**🔍 Why This Happens**: Database constraints enforce rules even when application code is bypassed

### 8. Inadequate Indexing

**❌ What Goes Wrong**:
```ruby
# Frequent queries without proper indexes
User.where(team_id: team.id, status: 'active')  # Slow without indexes
```

**⚠️ The Trap**: Forgetting performance implications of common queries

**✅ Solution**: Proper indexing strategy
```sql
CREATE INDEX idx_users_team_status ON users(team_id, status);
```

**🔍 Why This Happens**: Performance issues only surface under load

## User Experience Pitfalls

### 9. Broken User Flows

**❌ What Goes Wrong**:
```ruby
# Inconsistent user state handling
def create_team_member
  user = User.create!(params)  # What if user creation fails?
  send_welcome_email(user)     # Email sent even if team assignment fails
  user.update!(team: @team)    # Could fail, leaving user in inconsistent state
end
```

**⚠️ The Trap**: Not handling failure scenarios in multi-step processes

**✅ Solution**: Use database transactions
```ruby
def create_team_member
  User.transaction do
    user = User.create!(params)
    user.update!(team: @team)
    send_welcome_email(user)  # Only send after successful creation
  end
end
```

**🔍 Why This Happens**: Multi-step processes need atomic operations

### 10. Poor Error Handling

**❌ What Goes Wrong**:
```erb
<!-- Generic error messages -->
<% if @user.errors.any? %>
  <div>There were errors</div>  <!-- Unhelpful to users -->
<% end %>
```

**⚠️ The Trap**: Not providing actionable error information

**✅ Solution**: Specific, actionable error messages
```erb
<% @user.errors.full_messages.each do |message| %>
  <div class="error-message"><%= message %></div>
<% end %>
```

**🔍 Why This Happens**: Generic errors frustrate users and increase support burden

## Development Workflow Pitfalls

### 11. Insufficient Testing Strategy

**❌ What Goes Wrong**:
```ruby
# Only testing happy path
it "creates user successfully" do
  post :create, params: valid_params
  expect(response).to be_successful
end
# What about validation failures? Authorization failures? Edge cases?
```

**⚠️ The Trap**: Not testing failure scenarios and edge cases

**✅ Solution**: Comprehensive test coverage
```ruby
describe "user creation" do
  context "with valid params" do
    # Happy path tests
  end
  
  context "with invalid params" do
    # Validation failure tests
  end
  
  context "without authorization" do
    # Authorization failure tests
  end
end
```

**🔍 Why This Happens**: Failure scenarios are often overlooked during development

### 12. Debugging Without Logs

**❌ What Goes Wrong**:
```bash
# Making assumptions about errors instead of checking logs
"The user can't sign in" -> Implement complex workarounds
# Meanwhile, logs show: "Account locked due to failed attempts"
```

**⚠️ The Trap**: Assuming root causes instead of investigating

**✅ Solution**: Always check logs first
```bash
tail -50 log/development.log
grep -A 5 -B 5 "error_pattern" log/development.log
```

**🔍 Why This Happens**: Logs contain the actual error information

## Performance Pitfalls

### 13. N+1 Query Problems

**❌ What Goes Wrong**:
```erb
<!-- In view: loading teams and their members -->
<% @teams.each do |team| %>
  <%= team.name %> has <%= team.users.count %> members  <!-- N+1 query! -->
<% end %>
```

**⚠️ The Trap**: Lazy loading in views causes multiple database queries

**✅ Solution**: Eager loading in controller
```ruby
@teams = Team.includes(:users).all
```

**🔍 Why This Happens**: ActiveRecord's lazy loading is convenient but can hurt performance

### 14. Memory Leaks in Long-Running Processes

**❌ What Goes Wrong**:
```ruby
# Loading all records into memory
def export_all_users
  User.all.each do |user|  # Loads all users into memory!
    export_user(user)
  end
end
```

**⚠️ The Trap**: Loading large datasets into memory

**✅ Solution**: Use batch processing
```ruby
def export_all_users
  User.find_each(batch_size: 1000) do |user|
    export_user(user)
  end
end
```

**🔍 Why This Happens**: ActiveRecord makes it easy to accidentally load everything

## Deployment Pitfalls

### 15. Environment Configuration Mismatches

**❌ What Goes Wrong**:
```ruby
# Development configuration used in production
config.action_controller.raise_on_missing_callback_actions = false  # OK for dev
# But what about production? Different behavior!
```

**⚠️ The Trap**: Environment-specific configurations not properly managed

**✅ Solution**: Explicit configuration for each environment
```ruby
# config/environments/production.rb
config.action_controller.raise_on_missing_callback_actions = false
config.force_ssl = true
config.log_level = :warn
```

**🔍 Why This Happens**: Configuration needs differ between environments

## Prevention Strategies

### 1. Use Comprehensive Checklists
- [ ] Authorization implemented and tested
- [ ] Database constraints in place
- [ ] Error handling covers edge cases
- [ ] Performance impact considered
- [ ] Security implications reviewed

### 2. Implement Defensive Programming
- Always check for nil values
- Validate assumptions with conditionals
- Use database transactions for multi-step operations
- Handle failure scenarios gracefully

### 3. Regular Code Reviews
- Focus on security implications
- Check for common anti-patterns
- Verify test coverage
- Review performance impact

### 4. Comprehensive Testing
- Unit tests for models
- Integration tests for controllers
- Feature tests for user flows
- Security tests for authorization

### 5. Monitor and Measure
- Performance monitoring in production
- Error tracking and alerting
- User behavior analytics
- Security event logging

## Quick Reference: Common Mistakes

| Mistake | Impact | Quick Fix |
|---------|--------|-----------|
| Missing `devise_controller?` check | Auth interference | Add `unless: :devise_controller?` |
| Using `method: :delete` with Turbo | Broken links | Use `data: { "turbo-method": :delete }` |
| Using `link_to` for non-GET requests | Unreliable method handling | Use `button_to` instead |
| `to_param` affects admin routes | Wrong route parameters | Use `id: record.id` explicitly |
| Missing model methods in controllers | NoMethodError | Define all referenced methods |
| Using `confirm:` instead of `turbo_confirm:` | Broken confirmations | Use Turbo-compatible attributes |
| Permitting role in mass assignment | Security vulnerability | Validate and authorize parameters |
| Missing database constraints | Data integrity issues | Add CHECK constraints |
| No error handling in controllers | Poor UX | Handle exceptions gracefully |
| Forgetting to eager load | N+1 queries | Use `.includes()` |
| Not checking logs when debugging | Wrong assumptions | Always check logs first |

---

**Remember**: Most pitfalls are avoidable with defensive programming, comprehensive testing, and proper debugging practices. When in doubt, check the logs first!