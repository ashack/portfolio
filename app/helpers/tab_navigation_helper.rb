module TabNavigationHelper
  # Helper method to create tab configuration
  def build_tab(name:, path:, count: nil, badge: nil, badge_class: nil, active_paths: [])
    {
      name: name,
      path: path,
      count: count,
      badge: badge,
      badge_class: badge_class,
      active_paths: active_paths
    }
  end

  # Helper to render organization tabs
  def organization_tabs
    [
      build_tab(
        name: 'Teams',
        path: admin_super_teams_path,
        count: Team.count,
        active_paths: ['/admin/super/teams']
      ),
      build_tab(
        name: 'Enterprise Groups',
        path: admin_super_enterprise_groups_path,
        count: EnterpriseGroup.count,
        active_paths: ['/admin/super/enterprise_groups']
      )
    ]
  rescue => e
    Rails.logger.error "Error building organization tabs: #{e.message}"
    []
  end

  # Helper for user management tabs
  def user_management_tabs
    [
      build_tab(
        name: 'All Users',
        path: admin_super_users_path,
        count: User.count
      ),
      build_tab(
        name: 'Direct Users',
        path: admin_super_users_path(user_type: 'direct'),
        count: User.direct.count
      ),
      build_tab(
        name: 'Team Members',
        path: admin_super_users_path(user_type: 'invited'),
        count: User.invited.count
      ),
      build_tab(
        name: 'Enterprise Users',
        path: admin_super_users_path(user_type: 'enterprise'),
        count: User.enterprise.count
      )
    ]
  end

  # Helper for billing tabs
  def billing_tabs(team)
    [
      build_tab(
        name: 'Overview',
        path: team_admin_billing_path(team)
      ),
      build_tab(
        name: 'Subscription',
        path: team_admin_subscription_path(team),
        badge: team.plan.humanize,
        badge_class: 'bg-green-100 text-green-800'
      ),
      build_tab(
        name: 'Payment Methods',
        path: team_admin_payment_methods_path(team)
      ),
      build_tab(
        name: 'Invoices',
        path: team_admin_invoices_path(team),
        count: team.pay_charges.count
      )
    ]
  end

  # Generic tab builder for custom use cases
  def custom_tabs(&block)
    tabs = []
    builder = TabBuilder.new(tabs)
    yield(builder) if block_given?
    tabs
  end

  class TabBuilder
    def initialize(tabs)
      @tabs = tabs
    end

    def add(name, path, options = {})
      @tabs << {
        name: name,
        path: path,
        count: options[:count],
        badge: options[:badge],
        badge_class: options[:badge_class],
        active_paths: options[:active_paths] || []
      }
    end
  end
end