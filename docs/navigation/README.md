# Navigation System Documentation

## Overview

The application uses the **NavigationEngine** - a flexible, YAML-configurable Rails engine that provides centralized navigation management for all user types. This system offers:

- **YAML Configuration**: Define navigation structure in simple YAML files
- **I18n Support**: Full internationalization for navigation labels
- **Role-Based Visibility**: Show/hide items based on user permissions
- **Route Helper Support**: Use Rails route helpers instead of hardcoded paths
- **Dynamic Content**: Support for badges, ERB evaluation, and nested menus
- **Multiple Styles**: Sidebar, top navigation, and mobile-responsive views
- **Theme Support**: Different color themes for different user types
- **Caching**: Production-ready with configurable caching

## Architecture

The NavigationEngine is implemented as a Rails engine located at `engines/navigation_engine/` with these components:

### Core Components

1. **Configuration Loader** (`NavigationEngine::ConfigurationLoader`)
   - Loads YAML configuration with ERB support
   - Handles caching for performance
   - Processes dynamic navigation items

2. **Navigation Models**
   - `NavigationItem`: Individual navigation items with path resolution
   - `NavigationSection`: Groups of related navigation items

3. **Navigation Builder** (`NavigationEngine::NavigationBuilder`)
   - Processes navigation based on user permissions
   - Resolves dynamic paths and arguments
   - Handles active state detection

4. **Navigation Component** (`NavigationEngine::NavigationComponent`)
   - Renders navigation in different styles
   - Applies theme-based styling
   - Handles responsive behavior

## Configuration

### 1. Engine Setup

The engine is configured in `config/initializers/navigation_engine.rb`:

```ruby
NavigationEngine.setup do |config|
  config.configuration_file = "config/navigation.yml"
  config.cache_navigation = Rails.env.production?
  config.cache_expires_in = 1.hour
  config.i18n_scope = "navigation"
  config.default_icon_library = "phosphor"
  config.user_type_method = :user_type
  config.admin_check_methods = {
    super_admin: :super_admin?,
    site_admin: :site_admin?
  }
end
```

### 2. Navigation Structure

Define navigation in `config/navigation.yml`:

```yaml
navigation:
  # Admin navigation
  admin:
    super_admin:
      - type: section
        key: overview
        label: ".admin.overview"  # I18n key
        items:
          - key: dashboard
            label: ".admin.dashboard"
            path_helper: admin_super_dashboard_path
            icon: chart-pie-slice
            badge: :notifications_count  # Method call

  # Direct user navigation
  direct:
    - key: dashboard
      label: ".dashboard"
      path_helper: users_dashboard_path
      icon: house
      
  # Team navigation with dynamic paths
  team:
    admin:
      - key: members
        label: ".team.members"
        path_helper: teams_admin_members_path
        path_args:
          team_slug: "@team.slug"  # Instance variable
        icon: users
```

### 3. I18n Labels

Configure labels in `config/locales/navigation.en.yml`:

```yaml
en:
  navigation:
    admin:
      overview: "Overview"
      dashboard: "Dashboard"
    dashboard: "Dashboard"
    team:
      members: "Team Members"
```

## Usage

### Basic Usage

In your layout files:

```erb
<!-- Sidebar navigation -->
<%= navigation_for(current_user, style: :sidebar) %>

<!-- Mobile navigation -->
<%= navigation_for(current_user, style: :mobile) %>

<!-- Top navigation -->
<%= navigation_for(current_user, style: :top_nav) %>
```

### Helper Methods

```ruby
# Check if path is active
active_nav?("/dashboard")  # => true/false

# Render navigation icon
nav_icon("home", class: "w-5 h-5")

# Render navigation badge
nav_badge(5, type: :danger)

# Check navigation item visibility
can_see_nav_item?(:admin_dashboard)
```

## Advanced Features

### Dynamic Navigation Items

Use ERB in YAML for dynamic content:

```yaml
navigation:
  direct:
    - type: section
      key: teams
      label: "My Teams"
      permission: "owned_teams.any?"
      items: '<%= current_user.owned_teams.map { |team| 
        { 
          key: "team_#{team.id}", 
          label: team.name, 
          path_helper: "team_root_path", 
          path_args: { team_slug: team.slug },
          icon: "users"
        } 
      } %>'
```

### Permissions and Conditions

```yaml
items:
  - key: admin_area
    label: "Admin Area"
    # Symbol method
    permission: :admin?
    
    # String method with dot notation
    permission: "organization.admin?"
    
    # Additional condition
    condition: "proc { |user| user.beta_tester? }"
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

### Adding New Navigation

1. Edit `config/navigation.yml`
2. Add your navigation structure
3. Update I18n labels if needed
4. No code changes required!

### Custom Themes

The NavigationComponent supports themes:
- Default (indigo) for most users
- Purple for enterprise users

Customize in the NavigationComponent class if needed.

### Custom Icons

The engine uses a generic icon helper. Ensure your application provides:

```ruby
def icon(name, options = {})
  # Your icon rendering logic
  rails_icon(name, options)
end
```

## File Structure

```
config/
├── navigation.yml              # Navigation structure
├── locales/
│   └── navigation.en.yml      # I18n labels
└── initializers/
    └── navigation_engine.rb   # Engine configuration

engines/navigation_engine/
├── app/
│   ├── models/               # Navigation models
│   ├── services/            # Configuration loader & builder
│   ├── components/          # Navigation component
│   └── helpers/             # Navigation helpers
├── lib/
│   ├── navigation_engine.rb      # Engine module
│   └── navigation_engine/
│       └── engine.rb            # Engine configuration
└── README.md                    # Engine documentation
```

## Troubleshooting

### Navigation not showing
1. Check user type configuration
2. Verify permissions are returning expected values
3. Check Rails logs for route helper errors

### I18n labels not working
1. Ensure labels start with a dot (e.g., `.dashboard`)
2. Check I18n scope configuration
3. Verify translations exist in locale files

### Route helpers not found
1. Run `rails routes` to verify helper exists
2. Check path_args are correctly specified
3. Ensure the context has access to the helper

## Migration from Old System

The NavigationEngine replaces the previous implementation that used:
- `NavigationConfig` class → Now YAML configuration
- `NavigationBuilder` service → Now engine's builder
- `NavigationComponent` → Now engine's component
- Hardcoded paths → Now route helpers

All functionality has been preserved and enhanced in the new engine.

## Contributing

To modify the navigation engine:

1. Edit files in `engines/navigation_engine/`
2. Run tests: `cd engines/navigation_engine && bundle exec rake test`
3. Update documentation as needed

The NavigationEngine provides a maintainable, flexible solution for managing complex navigation structures while keeping configuration separate from code.