# NavigationEngine

A flexible, configurable navigation system for Rails applications that supports YAML configuration, role-based visibility, I18n, and multiple rendering styles.

## Features

- 📋 **YAML Configuration** - Define your navigation structure in a simple YAML file
- 🌐 **I18n Support** - Full internationalization support for navigation labels
- 🔐 **Role-Based Visibility** - Show/hide navigation items based on user permissions
- 🎨 **Multiple Styles** - Sidebar, top navigation, and mobile-responsive views
- 🚀 **Route Helper Support** - Use Rails route helpers instead of hardcoded paths
- 🏷️ **Dynamic Badges** - Add counters and status indicators to navigation items
- 🎯 **Active State Detection** - Automatic highlighting of current page
- 💎 **Rails Engine** - Easy to install and maintain as a separate gem

## Installation

Add the engine to your application:

```ruby
# In your main app's Gemfile
gem 'navigation_engine', path: 'engines/navigation_engine'
```

Then run:

```bash
bundle install
rails generate navigation_engine:install
```

The installer will:
- Add the engine to your Gemfile
- Create configuration files
- Mount engine routes
- Add helper to ApplicationController
- Copy necessary Stimulus controllers

## Configuration

### 1. Engine Configuration

Configure the engine in `config/initializers/navigation_engine.rb`:

```ruby
NavigationEngine.setup do |config|
  # Path to your navigation YAML configuration
  config.configuration_file = "config/navigation.yml"
  
  # Enable caching in production
  config.cache_navigation = Rails.env.production?
  
  # Cache expiration
  config.cache_expires_in = 1.hour
  
  # I18n scope for labels
  config.i18n_scope = "navigation"
  
  # Icon library
  config.default_icon_library = "phosphor"
  
  # User type detection
  config.user_type_method = :user_type
  
  # Admin check methods
  config.admin_check_methods = {
    super_admin: :super_admin?,
    site_admin: :site_admin?
  }
end
```

### 2. Navigation Structure

Define your navigation in `config/navigation.yml`:

```yaml
navigation:
  # Admin navigation
  admin:
    super_admin:
      - type: section
        key: overview
        label: ".admin.overview"  # Uses I18n
        items:
          - key: dashboard
            label: ".admin.dashboard"
            path_helper: admin_dashboard_path
            icon: chart-pie
            badge: :notifications_count  # Calls method on user
            
      - type: section
        key: users
        label: ".admin.users"
        permission: :can_manage_users?  # Permission check
        items:
          - key: all_users
            label: ".admin.all_users"
            path_helper: admin_users_path
            icon: users
            
  # Regular user navigation
  default:
    - key: dashboard
      label: ".dashboard"
      path_helper: dashboard_path
      icon: home
      
    - key: profile
      label: ".profile"
      path_helper: profile_path
      path_args:
        id: :id  # Dynamic argument
      icon: user
      
    # Dropdown menu
    - key: settings
      label: ".settings"
      icon: gear
      children:
        - key: account
          label: ".settings.account"
          path_helper: account_settings_path
          
        - key: notifications
          label: ".settings.notifications"
          path_helper: notification_settings_path
```

### 3. I18n Labels

Configure labels in `config/locales/navigation.en.yml`:

```yaml
en:
  navigation:
    admin:
      overview: "Overview"
      dashboard: "Dashboard"
      users: "User Management"
      all_users: "All Users"
    dashboard: "Dashboard"
    profile: "My Profile"
    settings: "Settings"
    settings:
      account: "Account Settings"
      notifications: "Notification Settings"
```

## Usage

### Basic Usage

In your layout files:

```erb
<!-- Sidebar navigation -->
<%= navigation_for(current_user, style: :sidebar) %>

<!-- Top navigation -->
<%= navigation_for(current_user, style: :top_nav) %>

<!-- Mobile navigation -->
<%= navigation_for(current_user, style: :mobile) %>
```

### Helper Methods

```ruby
# Check if a path is active
active_nav?("/dashboard")  # => true/false

# Render navigation icon
nav_icon("home", class: "w-5 h-5")

# Render navigation badge
nav_badge(5, type: :danger)

# Check if user can see specific navigation item
can_see_nav_item?(:admin_dashboard)  # => true/false
```

## Advanced Features

### Dynamic Navigation Items

Use ERB in your YAML configuration:

```yaml
navigation:
  direct:
    - key: teams
      label: "My Teams"
      permission: "owned_teams.any?"
      children: "<%= current_user.owned_teams.map { |team| 
        { 
          key: \"team_#{team.id}\", 
          label: team.name, 
          path_helper: 'team_path', 
          path_args: { id: team.id } 
        } 
      } %>"
```

### Custom Permissions

```yaml
items:
  - key: admin_area
    label: "Admin Area"
    # Symbol method
    permission: :admin?
    
    # String method with dot notation
    permission: "organization.admin?"
    
    # Proc (be careful with eval)
    permission: "proc { |user| user.role == 'admin' }"
```

### Path Arguments

```yaml
items:
  - key: team_dashboard
    label: "Team Dashboard"
    path_helper: team_dashboard_path
    path_args:
      # Instance variable from controller
      team_id: "@team.id"
      
      # Method call on current context
      slug: :current_team_slug
      
      # String interpolation
      name: "{{team_name}}"
```

### Conditional Visibility

```yaml
items:
  - key: beta_features
    label: "Beta Features"
    condition: "proc { |user, context| user.beta_tester? }"
```

### External Links

```yaml
items:
  - key: documentation
    label: "Documentation"
    path: "https://docs.example.com"
    external: true  # Opens in new tab
    icon: book
```

## Customization

### Custom Themes

The navigation component supports themes. By default, it uses:
- Default theme (indigo) for most users
- Purple theme for enterprise users

You can customize this in the NavigationComponent class.

### Custom Partials

Override the default navigation partials by creating your own:

```
app/views/navigation_engine/navigation/
├── _sidebar.html.erb
├── _sidebar_item.html.erb
├── _top_nav.html.erb
├── _top_nav_item.html.erb
└── _mobile.html.erb
```

### Custom Icons

The engine uses a generic icon helper that works with any icon library:

```ruby
# In your application helper
def icon(name, options = {})
  # Your icon rendering logic
  # e.g., for Phosphor icons:
  phosphor_icon(name, options)
end
```

## Testing

Test your navigation configuration:

```ruby
# In your test
test "admin can see admin navigation" do
  admin = users(:admin)
  builder = NavigationEngine::NavigationBuilder.new(
    user: admin,
    request: request,
    view_context: view
  )
  
  navigation = builder.build
  assert navigation.any? { |item| item[:key] == :admin_dashboard }
end
```

## Caching

Navigation is cached by default in production. To clear the cache:

```ruby
Rails.cache.delete_matched("navigation_engine/*")

# Or reload configuration
NavigationEngine.reload!
```

## Troubleshooting

### Navigation not showing up

1. Check that the user type is correctly configured
2. Verify permissions are returning expected values
3. Check the Rails logs for any errors in path helper resolution

### I18n labels not working

1. Ensure labels start with a dot (e.g., `.dashboard`)
2. Check that the I18n scope is correctly configured
3. Verify translations exist in your locale files

### Route helpers not working

1. Ensure the route helper exists (run `rails routes`)
2. Check that path_args are correctly specified
3. Verify the context has access to the helper method

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This engine is available as open source under the terms of the MIT License.