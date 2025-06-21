# Tab Navigation Component

## Overview

The TabNavigationComponent is a reusable ViewComponent that provides a consistent tab interface throughout the application. It's used in admin dashboards, user dashboards, and various other interfaces that require tabbed navigation.

## Component Structure

### Main Component
```ruby
class TabNavigationComponent < ViewComponent::Base
  renders_many :tabs, TabComponent
  
  def initialize(variant: :default, remember: false, id: nil)
    @variant = variant
    @remember = remember
    @id = id || SecureRandom.hex(4)
  end
end
```

### Tab Sub-Component
```ruby
class TabComponent < ViewComponent::Base
  attr_reader :name, :path, :count, :badge, :badge_class, :active
  
  def initialize(name:, path: nil, count: nil, badge: nil, badge_class: nil, active: false)
    # Component initialization
  end
end
```

## Usage

### Basic Usage
```erb
<%= render TabNavigationComponent.new do |nav| %>
  <% nav.with_tab(name: "Overview", path: dashboard_path) %>
  <% nav.with_tab(name: "Users", path: users_path, count: 42) %>
  <% nav.with_tab(name: "Settings", path: settings_path) %>
<% end %>
```

### With Badges
```erb
<%= render TabNavigationComponent.new do |nav| %>
  <% nav.with_tab(
    name: "Pending", 
    path: pending_path, 
    count: 5,
    badge: "New",
    badge_class: "bg-red-100 text-red-800"
  ) %>
<% end %>
```

### With Helper Methods
```erb
<%= render TabNavigationComponent.new do |nav| %>
  <% super_admin_tabs.each do |tab| %>
    <% nav.with_tab(**tab) %>
  <% end %>
<% end %>
```

## Helper Methods

### TabNavigationHelper
Located in `app/helpers/tab_navigation_helper.rb`, provides pre-configured tab sets:

#### Super Admin Tabs
```ruby
def super_admin_tabs
  [
    build_tab(
      name: "Dashboard",
      path: admin_super_root_path,
      count: nil,
      active_paths: ["/admin/super"]
    ),
    build_tab(
      name: "Users",
      path: admin_super_users_path,
      count: User.count,
      active_paths: ["/admin/super/users"]
    ),
    build_tab(
      name: "Teams",
      path: admin_super_teams_path,
      count: Team.count,
      active_paths: ["/admin/super/teams"]
    ),
    build_tab(
      name: "Enterprise Groups",
      path: admin_super_enterprise_groups_path,
      count: EnterpriseGroup.count,
      active_paths: ["/admin/super/enterprise_groups"]
    ),
    build_tab(
      name: "Plans",
      path: admin_super_plans_path,
      count: Plan.count,
      active_paths: ["/admin/super/plans"]
    )
  ]
end
```

#### Site Admin Organization Tabs
```ruby
def site_admin_organization_tabs
  [
    build_tab(
      name: "Teams",
      path: admin_site_organizations_path,
      count: Team.count,
      active_paths: ["/admin/site/teams", "/admin/site/organizations"]
    ),
    build_tab(
      name: "Enterprise Groups",
      path: admin_site_organizations_path(tab: "enterprise"),
      count: EnterpriseGroup.count,
      active_paths: ["/admin/site/enterprise_groups"]
    )
  ]
end
```

#### Enterprise Admin Tabs
```ruby
def enterprise_admin_tabs(enterprise_group)
  [
    build_tab(
      name: "Overview",
      path: enterprise_dashboard_path(enterprise_group_slug: enterprise_group.slug),
      active_paths: ["/enterprise/#{enterprise_group.slug}"]
    ),
    build_tab(
      name: "Members",
      path: members_path(enterprise_group_slug: enterprise_group.slug),
      count: enterprise_group.users.count,
      active_paths: ["/enterprise/#{enterprise_group.slug}/members"]
    ),
    build_tab(
      name: "Billing",
      path: billing_index_path(enterprise_group_slug: enterprise_group.slug),
      active_paths: ["/enterprise/#{enterprise_group.slug}/billing"]
    ),
    build_tab(
      name: "Settings",
      path: settings_path(enterprise_group_slug: enterprise_group.slug),
      active_paths: ["/enterprise/#{enterprise_group.slug}/settings"]
    )
  ]
end
```

## Tab State Management

### Active State Detection
The component automatically detects the active tab based on the current path:

1. **Exact Match**: If `path` matches `current_page?`
2. **Path Prefix**: If current path starts with any `active_paths`
3. **Manual Override**: If `active: true` is explicitly set

### Example Active State Logic
```ruby
def active?(request_path)
  return true if active_paths.any? { |path| request_path.start_with?(path) }
  return true if path && request_path == path
  false
end
```

## Styling

### Default Tab Styles
- **Active Tab**: `border-indigo-500 text-indigo-600`
- **Inactive Tab**: `border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300`

### Badge Styles
- **Active Badge**: `bg-indigo-100 text-indigo-600`
- **Inactive Badge**: `bg-gray-100 text-gray-900`
- **Custom Badge**: Use `badge_class` parameter

## View Component Template

The component template (`app/components/tab_navigation_component.html.erb`):
```erb
<div class="border-b border-gray-200">
  <nav class="-mb-px flex space-x-8" aria-label="Tabs">
    <% tabs.each do |tab| %>
      <% if tab.path %>
        <%= link_to tab.path, 
            class: "group inline-flex items-center py-4 px-1 border-b-2 font-medium text-sm #{tab.tab_classes}" do %>
          <span><%= tab.name %></span>
          <% if tab.count %>
            <span class="ml-3 py-0.5 px-2.5 rounded-full text-xs font-medium <%= tab.badge_classes %>">
              <%= tab.count %>
            </span>
          <% end %>
          <% if tab.badge %>
            <span class="ml-3 py-0.5 px-2.5 rounded-full text-xs font-medium <%= tab.badge_class || tab.badge_classes %>">
              <%= tab.badge %>
            </span>
          <% end %>
        <% end %>
      <% else %>
        <button type="button" 
                class="group inline-flex items-center py-4 px-1 border-b-2 font-medium text-sm <%= tab.tab_classes %>">
          <span><%= tab.name %></span>
          <% if tab.count %>
            <span class="ml-3 py-0.5 px-2.5 rounded-full text-xs font-medium <%= tab.badge_classes %>">
              <%= tab.count %>
            </span>
          <% end %>
        </button>
      <% end %>
    <% end %>
  </nav>
</div>
```

## Best Practices

### 1. Use Helper Methods
Create helper methods for commonly used tab sets:
```ruby
def user_dashboard_tabs
  [
    build_tab(name: "Overview", path: user_dashboard_path),
    build_tab(name: "Billing", path: users_billing_index_path),
    build_tab(name: "Settings", path: users_settings_path)
  ]
end
```

### 2. Consistent Active Path Logic
Always include all possible paths for a tab section:
```ruby
active_paths: [
  "/admin/super/users",
  "/admin/super/users/new",
  "/admin/super/users/#{id}/edit"
]
```

### 3. Count Performance
Use counter caches or scopes for efficient counts:
```ruby
count: User.active.count  # Good - uses indexed scope
count: User.where(complex_query).count  # Bad - expensive query
```

### 4. Tab Ordering
Keep tabs in a logical order:
1. Overview/Dashboard (first)
2. Primary features
3. Secondary features
4. Settings/Configuration (last)

## Common Patterns

### Conditional Tabs
```erb
<%= render TabNavigationComponent.new do |nav| %>
  <% nav.with_tab(name: "Public", path: public_path) %>
  <% if current_user.admin? %>
    <% nav.with_tab(name: "Admin", path: admin_path) %>
  <% end %>
<% end %>
```

### Dynamic Tab Content
```erb
<%= render TabNavigationComponent.new do |nav| %>
  <% @categories.each do |category| %>
    <% nav.with_tab(
      name: category.name,
      path: category_path(category),
      count: category.items_count
    ) %>
  <% end %>
<% end %>
```

### Tab with Dropdown (Future Enhancement)
```erb
<%= render TabNavigationComponent.new do |nav| %>
  <% nav.with_tab(name: "More", dropdown: true) do %>
    <!-- Dropdown content -->
  <% end %>
<% end %>
```

## Testing

### Component Tests
```ruby
class TabNavigationComponentTest < ViewComponent::TestCase
  def test_renders_tabs
    render_inline(TabNavigationComponent.new) do |nav|
      nav.with_tab(name: "Test", path: "/test")
    end
    
    assert_selector "nav"
    assert_text "Test"
  end
  
  def test_active_tab_styling
    with_request_url "/test" do
      render_inline(TabNavigationComponent.new) do |nav|
        nav.with_tab(name: "Test", path: "/test")
      end
      
      assert_selector ".border-indigo-500"
    end
  end
end
```

### System Tests
```ruby
test "user can navigate between tabs" do
  visit admin_super_root_path
  
  within "nav[aria-label='Tabs']" do
    click_link "Users"
  end
  
  assert_current_path admin_super_users_path
  assert_selector ".border-indigo-500", text: "Users"
end
```

## Future Enhancements

### Planned Features
1. **Persistent Tab State**: Remember selected tab across page loads
2. **Keyboard Navigation**: Arrow key support for tab switching
3. **Mobile Responsive**: Horizontal scroll or dropdown on mobile
4. **Tab Icons**: Support for Phosphor icons in tabs
5. **Tab Notifications**: Real-time count updates
6. **Nested Tabs**: Support for sub-navigation
7. **Tab Analytics**: Track tab usage patterns

### Variant Support
Future variants for different contexts:
- `:pills` - Pill-style tabs
- `:vertical` - Vertical tab layout
- `:minimal` - Minimal styling
- `:boxed` - Boxed tab style