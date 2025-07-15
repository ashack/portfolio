# Create default notification categories
puts "Creating default notification categories..."

# Find a super admin to be the creator
admin_user = User.find_by(system_role: 'super_admin') || User.first

if admin_user
  # System-wide notification categories
  system_categories = [
    {
      name: 'Security Alerts',
      key: 'security_alerts',
      description: 'Critical security notifications that cannot be disabled',
      icon: 'shield-warning',
      color: 'red',
      allow_user_disable: false,
      default_priority: 'critical',
      send_email: true
    },
    {
      name: 'Account Updates',
      key: 'account_updates',
      description: 'Notifications about account changes and profile updates',
      icon: 'user-circle',
      color: 'blue',
      allow_user_disable: true,
      default_priority: 'medium',
      send_email: true
    },
    {
      name: 'System Announcements',
      key: 'system_announcements',
      description: 'Platform-wide announcements and updates',
      icon: 'megaphone',
      color: 'purple',
      allow_user_disable: true,
      default_priority: 'medium',
      send_email: false
    },
    {
      name: 'Billing & Payments',
      key: 'billing_payments',
      description: 'Payment receipts, subscription updates, and billing notifications',
      icon: 'credit-card',
      color: 'green',
      allow_user_disable: false,
      default_priority: 'high',
      send_email: true
    },
    {
      name: 'Login Activity',
      key: 'login_activity',
      description: 'Notifications about login events and session activity',
      icon: 'sign-in',
      color: 'yellow',
      allow_user_disable: true,
      default_priority: 'low',
      send_email: false
    },
    {
      name: 'Team Invitations',
      key: 'team_invitations',
      description: 'Notifications about team invitations and membership',
      icon: 'envelope',
      color: 'indigo',
      allow_user_disable: false,
      default_priority: 'high',
      send_email: true
    },
    {
      name: 'Feature Updates',
      key: 'feature_updates',
      description: 'Information about new features and improvements',
      icon: 'rocket',
      color: 'purple',
      allow_user_disable: true,
      default_priority: 'low',
      send_email: false
    },
    {
      name: 'Maintenance Notices',
      key: 'maintenance_notices',
      description: 'Scheduled maintenance and downtime notifications',
      icon: 'wrench',
      color: 'gray',
      allow_user_disable: false,
      default_priority: 'high',
      send_email: true
    }
  ]

  system_categories.each do |attrs|
    category = NotificationCategory.find_or_create_by!(key: attrs[:key]) do |cat|
      cat.attributes = attrs.merge(
        scope: 'system',
        created_by: admin_user
      )
    end
    puts "  Created/Updated system category: #{category.name}"
  end

  # Create some example team-specific categories if there are teams
  Team.active.limit(2).each do |team|
    next unless team.admin

    team_categories = [
      {
        name: 'Task Assignments',
        key: "team_#{team.id}_task_assignments",
        description: 'Notifications when tasks are assigned to you',
        icon: 'clipboard-text',
        color: 'blue',
        allow_user_disable: true,
        default_priority: 'medium',
        send_email: true
      },
      {
        name: 'Team Updates',
        key: "team_#{team.id}_updates",
        description: 'Important updates from team administrators',
        icon: 'users-three',
        color: 'green',
        allow_user_disable: true,
        default_priority: 'medium',
        send_email: false
      }
    ]

    team_categories.each do |attrs|
      category = NotificationCategory.find_or_create_by!(key: attrs[:key]) do |cat|
        cat.attributes = attrs.merge(
          scope: 'team',
          team: team,
          created_by: team.admin
        )
      end
      puts "  Created/Updated team category for #{team.name}: #{category.name}"
    end
  end

  # Create some example enterprise-specific categories if there are enterprise groups
  EnterpriseGroup.active.limit(2).each do |enterprise|
    next unless enterprise.admin

    enterprise_categories = [
      {
        name: 'Compliance Updates',
        key: "enterprise_#{enterprise.id}_compliance",
        description: 'Compliance and regulatory notifications',
        icon: 'shield-check',
        color: 'purple',
        allow_user_disable: false,
        default_priority: 'high',
        send_email: true
      },
      {
        name: 'Organization News',
        key: "enterprise_#{enterprise.id}_news",
        description: 'News and updates from the organization',
        icon: 'newspaper',
        color: 'indigo',
        allow_user_disable: true,
        default_priority: 'low',
        send_email: false
      }
    ]

    enterprise_categories.each do |attrs|
      category = NotificationCategory.find_or_create_by!(key: attrs[:key]) do |cat|
        cat.attributes = attrs.merge(
          scope: 'enterprise',
          enterprise_group: enterprise,
          created_by: enterprise.admin
        )
      end
      puts "  Created/Updated enterprise category for #{enterprise.name}: #{category.name}"
    end
  end

  puts "✓ Default notification categories created successfully!"
else
  puts "⚠ No admin user found. Skipping notification category creation."
end
