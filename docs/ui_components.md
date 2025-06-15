# UI Components & Design System

## Overview

This SaaS application features a comprehensive UI component system built with Tailwind CSS and modern web standards. The design emphasizes consistency, accessibility, and professional appearance across all user interfaces.

## Icon System - Phosphor Icons

### Integration

The application uses the `rails_icons` gem with the Phosphor icon library for consistent, high-quality icons throughout the interface.

**Configuration:**
```ruby
# config/initializers/rails_icons.rb
RailsIcons.configure do |config|
  config.default_library = "phosphor"
end
```

### Usage

**Basic Icon Usage:**
```erb
<%= icon "users", class: "h-6 w-6 text-blue-400" %>
<%= icon "check-circle", class: "h-5 w-5 text-green-500" %>
<%= icon "gear", class: "h-4 w-4 text-gray-600" %>
```

**Icon Variants:**
```erb
<!-- Regular (default) -->
<%= icon "heart", class: "h-6 w-6" %>

<!-- Fill variant -->
<%= icon "heart", variant: :fill, class: "h-6 w-6" %>

<!-- With additional attributes -->
<%= icon "x", variant: :fill, class: "h-6 w-6 text-red-500 cursor-pointer", role: "button" %>
```

### Available Icons

The application has access to the complete Phosphor icon library with the following variants:
- **Regular** (default)
- **Fill**
- **Bold** 
- **Light**
- **Thin**
- **Duotone**

Common icons used throughout the application:
- `users` - User management and team icons
- `users-three` - Team/group indicators
- `check-circle` - Success states and confirmations
- `warning` - Alerts and warnings
- `lock` - Security and restricted access
- `gear` - Settings and configuration
- `envelope` - Email and messaging
- `currency-dollar` - Billing and payments
- `chart-bar` - Analytics and reporting
- `pencil` - Edit actions
- `house` - Dashboard/home
- `shield-star` - Admin privileges
- `lifebuoy` - Support and help

### Implementation Locations

**Admin Dashboards:**
- Super Admin Dashboard: `/app/views/admin/super/dashboard/index.html.erb`
- Site Admin Dashboard: `/app/views/admin/site/dashboard/index.html.erb`

**Team Interfaces:**
- Team Dashboard: `/app/views/teams/dashboard/index.html.erb`
- Team Admin Dashboard: `/app/views/teams/admin/dashboard/index.html.erb`

**User Interfaces:**
- User Dashboard: `/app/views/users/dashboard/index.html.erb`

**Layouts:**
- Admin Layout: `/app/views/layouts/admin.html.erb`
- Team Layout: `/app/views/layouts/team.html.erb`

## Design System

### Color Palette

**Primary Colors:**
- `text-indigo-600` / `bg-indigo-600` - Primary actions and branding
- `text-blue-400` / `bg-blue-400` - Information and secondary actions

**Status Colors:**
- `text-green-500` / `bg-green-100` - Success states
- `text-yellow-400` / `bg-yellow-100` - Warning states  
- `text-red-500` / `bg-red-100` - Error states
- `text-gray-400` / `bg-gray-100` - Neutral states

**UI Colors:**
- `bg-white` - Card backgrounds
- `bg-gray-50` - Page backgrounds
- `bg-gray-800` - Navigation sidebars
- `text-gray-900` - Primary text
- `text-gray-500` - Secondary text

### Typography

**Headings:**
```css
.text-2xl.font-bold - Page titles
.text-lg.font-medium - Section headings
.text-sm.font-medium - Card titles
.text-xs.font-semibold - Labels
```

**Body Text:**
```css
.text-sm - Primary body text
.text-xs - Secondary/helper text
```

### Layout Components

**Cards:**
```erb
<div class="bg-white overflow-hidden shadow rounded-lg">
  <div class="p-5">
    <!-- Card content -->
  </div>
</div>
```

**Stats Cards:**
```erb
<div class="bg-white overflow-hidden shadow rounded-lg">
  <div class="p-5">
    <div class="flex items-center">
      <div class="flex-shrink-0">
        <%= icon "icon-name", class: "h-6 w-6 text-color" %>
      </div>
      <div class="ml-5 w-0 flex-1">
        <dl>
          <dt class="text-sm font-medium text-gray-500 truncate">Label</dt>
          <dd class="text-lg font-medium text-gray-900">Value</dd>
        </dl>
      </div>
    </div>
  </div>
</div>
```

**Action Buttons:**
```erb
<!-- Primary Button -->
<%= link_to path, class: "inline-flex items-center justify-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700" do %>
  <%= icon "icon-name", class: "-ml-1 mr-2 h-4 w-4" %>
  Button Text
<% end %>

<!-- Secondary Button -->
<%= link_to path, class: "inline-flex items-center justify-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50" do %>
  <%= icon "icon-name", class: "-ml-1 mr-2 h-4 w-4" %>
  Button Text
<% end %>
```

### Navigation

**Sidebar Navigation:**
```erb
<%= link_to path, class: "#{active_class} group flex items-center px-2 py-2 text-base font-medium rounded-md mb-1" do %>
  <%= icon "icon-name", class: "mr-4 h-6 w-6" %>
  Navigation Item
<% end %>
```

**Status Badges:**
```erb
<span class="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
  Active
</span>
```

## Responsive Design

### Breakpoints

- **Mobile**: Default styles (< 640px)
- **Small**: `sm:` (≥ 640px)
- **Medium**: `md:` (≥ 768px)  
- **Large**: `lg:` (≥ 1024px)
- **Extra Large**: `xl:` (≥ 1280px)

### Grid Systems

**Dashboard Grids:**
```erb
<div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
  <!-- Responsive grid items -->
</div>
```

**Content Grids:**
```erb
<div class="grid grid-cols-1 gap-8 lg:grid-cols-2">
  <!-- Two-column layout on large screens -->
</div>
```

## Accessibility

### Icon Accessibility

**Semantic Icons:**
```erb
<%= icon "check", class: "h-5 w-5", "aria-label": "Success" %>
```

**Decorative Icons:**
```erb
<%= icon "users", class: "h-6 w-6", "aria-hidden": "true" %>
```

### Color Contrast

All color combinations meet WCAG 2.1 AA standards:
- Text on backgrounds maintains 4.5:1 contrast ratio
- Interactive elements have sufficient contrast
- Status colors are distinguishable for colorblind users

### Focus States

Interactive elements include proper focus indicators:
```css
.focus:outline-none .focus:ring-2 .focus:ring-indigo-500
```

## Performance

### Icon Optimization

- Icons are served as optimized SVG files
- No external font dependencies  
- Minimal HTTP requests through asset pipeline
- Cached icon files for fast loading

### CSS Optimization

- Tailwind CSS purged in production
- Critical CSS inlined for above-the-fold content
- Non-critical CSS loaded asynchronously

## Browser Support

**Supported Browsers:**
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

**Progressive Enhancement:**
- Base functionality works in older browsers
- Enhanced features for modern browsers
- Graceful degradation for unsupported features

## Development Guidelines

### Adding New Icons

1. Choose appropriate icon from Phosphor library
2. Use consistent sizing classes (`h-4 w-4`, `h-5 w-5`, `h-6 w-6`)
3. Apply appropriate color classes for context
4. Add accessibility attributes when needed

### Maintaining Consistency

1. Follow established color patterns
2. Use standard spacing and sizing
3. Maintain responsive behavior
4. Test across different screen sizes

### Icon Naming Conventions

- Use descriptive icon names that match their purpose
- Prefer semantic names over visual descriptions
- Check icon availability before using new icons
- Document custom icon usage in this file

## Future Enhancements

### Planned Improvements

- [ ] Dark mode theme support
- [ ] Enhanced animation system
- [ ] Component library documentation
- [ ] Storybook integration for component testing
- [ ] Additional icon variants and customization
- [ ] Advanced accessibility features

### Design System Evolution

- [ ] Design tokens for consistent theming
- [ ] Component abstraction for reusability
- [ ] Advanced responsive patterns
- [ ] Performance optimization guidelines