# Shared test data module for both Rails tests and E2E tests
# This ensures consistency between different test types

module SharedTestData
  class << self
    # Create a standard set of test users
    def create_test_users
      {
        super_admin: create_user(
          email: ENV['TEST_SUPER_ADMIN_EMAIL'] || 'super@example.com',
          password: ENV['TEST_SUPER_ADMIN_PASSWORD'] || 'Password123!',
          system_role: 'super_admin',
          user_type: 'direct',
          first_name: 'Super',
          last_name: 'Admin'
        ),
        
        site_admin: create_user(
          email: ENV['TEST_SITE_ADMIN_EMAIL'] || 'site@example.com',
          password: ENV['TEST_SITE_ADMIN_PASSWORD'] || 'Password123!',
          system_role: 'site_admin',
          user_type: 'direct',
          first_name: 'Site',
          last_name: 'Admin'
        ),
        
        direct_user: create_user(
          email: ENV['TEST_DIRECT_USER_EMAIL'] || 'direct@example.com',
          password: ENV['TEST_DIRECT_USER_PASSWORD'] || 'Password123!',
          system_role: 'user',
          user_type: 'direct',
          first_name: 'Direct',
          last_name: 'User'
        ),
        
        team_admin: create_user(
          email: ENV['TEST_TEAM_ADMIN_EMAIL'] || 'teamadmin@example.com',
          password: ENV['TEST_TEAM_ADMIN_PASSWORD'] || 'Password123!',
          system_role: 'user',
          user_type: 'direct', # Will be updated when assigned to team
          first_name: 'Team',
          last_name: 'Admin'
        ),
        
        team_member: create_user(
          email: ENV['TEST_TEAM_MEMBER_EMAIL'] || 'member@example.com',
          password: ENV['TEST_TEAM_MEMBER_PASSWORD'] || 'Password123!',
          system_role: 'user',
          user_type: 'direct', # Will be updated when assigned to team
          first_name: 'Team',
          last_name: 'Member'
        ),
        
        enterprise_admin: create_user(
          email: ENV['TEST_ENTERPRISE_ADMIN_EMAIL'] || 'entadmin@example.com',
          password: ENV['TEST_ENTERPRISE_ADMIN_PASSWORD'] || 'Password123!',
          system_role: 'user',
          user_type: 'enterprise',
          first_name: 'Enterprise',
          last_name: 'Admin'
        )
      }
    end

    # Create edge case users for testing
    def create_edge_case_users
      {
        unconfirmed: create_user(
          email: 'unconfirmed@example.com',
          password: 'Password123!',
          confirmed_at: nil,
          first_name: 'Unconfirmed',
          last_name: 'User'
        ),
        
        locked: create_user(
          email: 'locked@example.com',
          password: 'Password123!',
          locked_at: Time.current,
          failed_attempts: 5,
          first_name: 'Locked',
          last_name: 'User'
        ),
        
        inactive: create_user(
          email: 'inactive@example.com',
          password: 'Password123!',
          status: 'inactive',
          first_name: 'Inactive',
          last_name: 'User'
        )
      }
    end

    # Create test plans
    def create_test_plans
      {
        individual_free: Plan.find_or_create_by!(name: 'Individual Free') do |p|
          p.plan_segment = 'individual'
          p.amount_cents = 0
          p.features = ['basic_dashboard', 'email_support']
          p.active = true
        end,
        
        individual_pro: Plan.find_or_create_by!(name: 'Individual Pro') do |p|
          p.plan_segment = 'individual'
          p.stripe_price_id = 'price_test_individual_pro'
          p.amount_cents = 1900
          p.interval = 'month'
          p.features = ['basic_dashboard', 'advanced_features', 'priority_support']
          p.active = true
        end,
        
        team_starter: Plan.find_or_create_by!(name: 'Team Starter') do |p|
          p.plan_segment = 'team'
          p.stripe_price_id = 'price_test_team_starter'
          p.amount_cents = 4900
          p.interval = 'month'
          p.max_team_members = 5
          p.features = ['team_dashboard', 'member_management', 'team_billing']
          p.active = true
        end,
        
        team_pro: Plan.find_or_create_by!(name: 'Team Pro') do |p|
          p.plan_segment = 'team'
          p.stripe_price_id = 'price_test_team_pro'
          p.amount_cents = 9900
          p.interval = 'month'
          p.max_team_members = 15
          p.features = ['team_dashboard', 'member_management', 'team_billing', 'advanced_analytics']
          p.active = true
        end,
        
        enterprise: Plan.find_or_create_by!(name: 'Enterprise') do |p|
          p.plan_segment = 'enterprise'
          p.stripe_price_id = 'price_test_enterprise'
          p.amount_cents = 19900
          p.interval = 'month'
          p.max_team_members = 100
          p.features = ['enterprise_dashboard', 'sso', 'dedicated_support', 'custom_integrations']
          p.active = true
        end
      }
    end

    # Create notification categories
    def create_notification_categories
      # Ensure we have a system user to create categories
      system_user = User.find_or_create_by!(email: 'system@example.com') do |u|
        u.password = 'SystemPassword123!'
        u.user_type = 'direct'
        u.system_role = 'super_admin'
        u.status = 'active'
        u.confirmed_at = Time.current
        u.first_name = 'System'
        u.last_name = 'User'
      end
      
      {
        system: NotificationCategory.find_or_create_by!(key: 'system') do |c|
          c.name = 'System Notifications'
          c.description = 'Important system updates and maintenance notifications'
          c.scope = 'system'
          c.created_by = system_user
          c.active = true
          c.allow_user_disable = false
        end,
        
        security: NotificationCategory.find_or_create_by!(key: 'security') do |c|
          c.name = 'Security Alerts'
          c.description = 'Security-related notifications like login attempts and password changes'
          c.scope = 'system'
          c.created_by = system_user
          c.active = true
          c.allow_user_disable = false
        end,
        
        team: NotificationCategory.find_or_create_by!(key: 'team_updates') do |c|
          c.name = 'Team Updates'
          c.description = 'Notifications about team activities and member changes'
          c.scope = 'system'
          c.created_by = system_user
          c.active = true
          c.allow_user_disable = true
        end,
        
        billing: NotificationCategory.find_or_create_by!(key: 'billing') do |c|
          c.name = 'Billing & Subscription'
          c.description = 'Payment, subscription, and billing-related notifications'
          c.scope = 'system'
          c.created_by = system_user
          c.active = true
          c.allow_user_disable = true
        end
      }
    end

    # Create a test team with admin
    def create_test_team(name: 'Test Team', admin_user: nil)
      admin_user ||= User.find_by(system_role: 'super_admin')
      plan = Plan.find_by(plan_segment: 'team', name: 'Team Starter')
      
      team = Team.create!(
        name: name,
        created_by: admin_user,
        admin: admin_user,
        plan_id: plan.id,
        stripe_customer_id: "cus_test_#{SecureRandom.hex(8)}",
        status: 'active'
      )
      
      # Update admin's association
      admin_user.update!(
        team: team,
        team_role: 'admin',
        user_type: 'invited' # Admin becomes invited type when assigned to team
      )
      
      team
    end

    # Create a test enterprise group
    def create_test_enterprise_group(name: 'Test Enterprise', admin_email: 'entadmin@example.com')
      admin = User.find_or_create_by!(email: admin_email) do |u|
        u.password = 'Password123!'
        u.user_type = 'enterprise'
        u.system_role = 'user'
        u.status = 'active'
        u.confirmed_at = Time.current
        u.first_name = 'Enterprise'
        u.last_name = 'Admin'
      end
      
      plan = Plan.find_by(plan_segment: 'enterprise')
      creator = User.find_by(system_role: 'super_admin')
      
      enterprise = EnterpriseGroup.create!(
        name: name,
        created_by: creator,
        admin: admin,
        plan_id: plan.id,
        stripe_customer_id: "cus_test_#{SecureRandom.hex(8)}",
        status: 'active'
      )
      
      # Update admin's association
      admin.update!(
        enterprise_group: enterprise,
        enterprise_group_role: 'admin'
      )
      
      enterprise
    end

    # Setup complete test environment
    def setup_test_environment
      # Create plans first
      plans = create_test_plans
      
      # Create notification categories
      categories = create_notification_categories
      
      # Create users
      users = create_test_users
      edge_users = create_edge_case_users
      
      # Return all created data
      {
        plans: plans,
        categories: categories,
        users: users.merge(edge_users)
      }
    end

    private

    def create_user(attributes = {})
      defaults = {
        password: 'Password123!',
        password_confirmation: 'Password123!',
        status: 'active',
        confirmed_at: Time.current,
        timezone: 'UTC',
        locale: 'en',
        profile_visibility: 0
      }
      
      User.find_or_create_by!(email: attributes[:email]) do |user|
        user.assign_attributes(defaults.merge(attributes))
      end
    end
  end
end