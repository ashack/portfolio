# Enterprise Features Documentation

## Overview

The Enterprise Features module provides a complete enterprise-grade user management system for large organizations with custom requirements. This system operates independently from the team-based and individual user systems.

## Architecture

### Triple-Track User System

The application now supports three distinct user ecosystems:

1. **Direct Users**: Individual users with personal billing who can also create teams
2. **Invited Users**: Team members who join via invitation only
3. **Enterprise Users**: Large organizations with custom plans and centralized management

### Enterprise User Flow

```
1. Super Admin creates Enterprise Group
2. Super Admin sends invitation to designated admin
3. Admin accepts invitation and gains access to enterprise dashboard
4. Admin can invite additional enterprise users
5. Enterprise users access dedicated enterprise workspace
```

## Database Schema

### Enterprise Groups Table
```sql
CREATE TABLE enterprise_groups (
  id BIGINT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  admin_id BIGINT REFERENCES users(id),
  created_by_id BIGINT NOT NULL REFERENCES users(id),
  plan_id BIGINT NOT NULL REFERENCES plans(id),
  status ENUM('active', 'suspended', 'cancelled') DEFAULT 'active',
  stripe_customer_id VARCHAR(255),
  trial_ends_at TIMESTAMP,
  current_period_end TIMESTAMP,
  settings JSON,
  max_members INTEGER DEFAULT 100,
  custom_domain VARCHAR(255),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Polymorphic Invitations
The invitations table now supports both team and enterprise invitations:
```ruby
# invitable_type: 'Team' or 'EnterpriseGroup'
# invitable_id: ID of the team or enterprise group
# invitation_type: 'team' or 'enterprise'
```

## Models

### EnterpriseGroup Model
```ruby
class EnterpriseGroup < ApplicationRecord
  include Pay::Billable
  
  belongs_to :admin, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :plan
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, as: :invitable, dependent: :destroy
  
  enum status: { active: 0, suspended: 1, cancelled: 2 }
  
  # Admin is optional during creation (set when invitation accepted)
  validates :admin_id, presence: true, on: :update, if: :admin_required?
end
```

### User Model Updates
```ruby
# New user type
enum user_type: { direct: 0, invited: 1, enterprise: 2 }

# Enterprise associations
belongs_to :enterprise_group, optional: true
enum enterprise_group_role: { member: 0, admin: 1 }
```

## Controllers

### Enterprise Namespace Structure
```
/app/controllers/enterprise/
├── base_controller.rb          # Authentication and group loading
├── dashboard_controller.rb     # Enterprise dashboard
├── members_controller.rb       # Member management
├── billing_controller.rb       # Billing and subscriptions
├── settings_controller.rb      # Group settings
└── profile_controller.rb       # User profile management
```

### Key Controller Features

#### Base Controller
- Authenticates enterprise users
- Loads enterprise group from slug
- Verifies user belongs to the group

#### Members Controller
- Full CRUD for member invitations
- Resend and revoke invitation functionality
- Role management (admin/member)
- Member deletion

#### Billing Controller
- Payment method management
- Subscription overview
- Invoice history
- Plan upgrades

## Views and UI

### Purple Theme
Enterprise interfaces use a distinctive purple color scheme:
- Primary: `purple-600`
- Hover: `purple-700`
- Light: `purple-100`
- Background: `purple-50`

### Layout Structure
```erb
<!-- /app/views/layouts/enterprise.html.erb -->
<div class="flex h-screen bg-gray-50">
  <!-- Purple-themed sidebar -->
  <aside class="w-64 bg-purple-900">
    <!-- Navigation -->
  </aside>
  
  <!-- Main content area -->
  <main class="flex-1">
    <!-- Page content -->
  </main>
</div>
```

### Dashboard Features
- Member statistics
- Quick actions
- Recent activity
- Billing summary
- Admin-only sections

## Routing

### Enterprise Routes
```ruby
scope "/enterprise/:enterprise_group_slug" do
  root "enterprise/dashboard#index", as: :enterprise_dashboard
  
  resources :members do
    member do
      post :resend_invitation
      delete :revoke_invitation
    end
  end
  
  resources :billing, only: [:index, :show] do
    collection do
      post :update_payment_method
      post :cancel_subscription
    end
  end
  
  resource :settings, only: [:show, :update]
  resources :profile, only: [:show, :edit, :update]
end
```

### Admin Routes for Enterprise Management
```ruby
namespace :admin do
  namespace :super do
    resources :enterprise_groups do
      resources :invitations, controller: "enterprise_group_invitations"
    end
  end
  
  namespace :site do
    resources :enterprise_groups, only: [:show]
    resources :organizations # Unified view with tabs
  end
end
```

## Invitation Flow

### Creating Enterprise Groups
1. Super Admin creates group with name and plan
2. System generates unique slug
3. Admin field left empty initially
4. Invitation sent to designated admin email

### Invitation Process
```ruby
# 1. Create invitation
invitation = enterprise_group.invitations.create!(
  email: admin_email,
  role: "admin",
  invitation_type: "enterprise",
  invited_by: current_user
)

# 2. Send email
InvitationMailer.with(invitation: invitation).invite.deliver_now

# 3. Accept invitation
user = invitation.accept!(user_attributes)

# 4. Set as group admin
enterprise_group.update!(admin: user)
```

### Invitation States
- **Pending**: Not yet accepted
- **Accepted**: User created and active
- **Expired**: Past 7-day expiration
- **Revoked**: Cancelled by admin

## Security

### Authentication
- Enterprise users must have `user_type: 'enterprise'`
- Must belong to an enterprise group
- Cannot access team or individual features

### Authorization
```ruby
# Enterprise admin abilities
- Manage all group members
- Access billing and settings
- Invite new members
- Revoke pending invitations
- Delete members

# Enterprise member abilities
- Access enterprise dashboard
- View other members
- Update own profile
- Cannot access billing or settings
```

### Pundit Policies
```ruby
class EnterpriseGroupPolicy < ApplicationPolicy
  def show?
    super_admin? || site_admin? || member?
  end
  
  def admin_access?
    super_admin? || enterprise_admin?
  end
  
  private
  
  def member?
    user.enterprise_group_id == record.id
  end
  
  def enterprise_admin?
    member? && user.enterprise_group_role == 'admin'
  end
end
```

## Tab Navigation

### Site Admin Organizations View
Site admins can view both teams and enterprise groups through a unified tab interface:

```ruby
# Teams Tab
- Shows all teams
- Team details and members
- Activity tracking

# Enterprise Groups Tab
- Shows all enterprise groups
- Group details and members
- Admin information
- Invitation status
```

### Tab Component Usage
```erb
<%= render TabNavigationComponent.new do |nav| %>
  <% site_admin_organization_tabs.each do |tab| %>
    <% nav.with_tab(**tab) %>
  <% end %>
<% end %>
```

## Email Configuration

### Development Environment
Uses letter_opener for email preview:
```ruby
# Invitations open automatically in browser
InvitationMailer.with(invitation: invitation).invite.deliver_now
```

### Production Environment
Configure actual email delivery:
```ruby
InvitationMailer.with(invitation: invitation).invite.deliver_later
```

## Best Practices

### 1. Invitation Management
- Always validate email doesn't exist in users table
- Set appropriate expiration times
- Log all invitation actions
- Send reminders for pending invitations

### 2. Security
- Verify enterprise group membership on every request
- Use slug-based URLs for security through obscurity
- Implement proper rate limiting for invitations
- Audit log all administrative actions

### 3. UI/UX
- Maintain consistent purple theme
- Show clear role indicators
- Provide invitation status badges
- Include help text for complex features

### 4. Performance
- Index slug columns for fast lookups
- Eager load associations to prevent N+1
- Cache enterprise group data
- Use background jobs for email delivery

## Troubleshooting

### Common Issues

1. **"Admin must exist" error**
   - Solution: Admin is optional during creation, set via invitation

2. **Invitation not updating status**
   - Check invitation_type is set correctly
   - Verify accept! method is called in registration

3. **Double "enterprise" in URLs**
   - Remove namespace from routes
   - Use explicit controller paths

4. **Site admin can't see enterprise groups**
   - Ensure organizations controller handles tabs
   - Check policy allows site admin access

### Debug Checklist
- [ ] User type is 'enterprise'
- [ ] Enterprise group association exists
- [ ] Invitation type is 'enterprise'
- [ ] Polymorphic association is set
- [ ] Email delivery is configured
- [ ] Routes are properly scoped

## Future Enhancements

### Planned Features
1. **SSO Integration**
   - SAML support
   - OAuth providers
   - Active Directory sync

2. **Advanced Permissions**
   - Granular role-based access
   - Custom permission sets
   - Department-based access

3. **Enterprise Analytics**
   - Usage dashboards
   - Cost allocation
   - Compliance reporting

4. **API Access**
   - Enterprise API keys
   - Usage quotas
   - Webhook integration

### Migration Path
For existing teams wanting to upgrade to enterprise:
1. Create enterprise group
2. Migrate team data
3. Update user associations
4. Transfer billing
5. Archive old team