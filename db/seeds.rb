puts "=== Creating Plans ==="

# Create Individual Plans
individual_plans = [
  {
    name: 'Individual Free',
    plan_segment: 'individual',
    amount_cents: 0,
    features: [ 'basic_dashboard', 'email_support' ],
    active: true
  },
  {
    name: 'Individual Pro',
    plan_segment: 'individual',
    stripe_price_id: ENV['STRIPE_INDIVIDUAL_PRO_PRICE_ID'] || 'price_individual_pro',
    amount_cents: 1900,
    interval: 'month',
    features: [ 'basic_dashboard', 'advanced_features', 'priority_support' ],
    active: true
  },
  {
    name: 'Individual Premium',
    plan_segment: 'individual',
    stripe_price_id: ENV['STRIPE_INDIVIDUAL_PREMIUM_PRICE_ID'] || 'price_individual_premium',
    amount_cents: 4900,
    interval: 'month',
    features: [ 'basic_dashboard', 'advanced_features', 'premium_features', 'phone_support' ],
    active: true
  }
]

individual_plans.each do |plan_attrs|
  plan = Plan.find_or_create_by!(name: plan_attrs[:name]) do |p|
    p.attributes = plan_attrs
  end
  puts "Created individual plan: #{plan.name}"
end

# Create Team Plans
team_plans = [
  {
    name: 'Team Starter',
    plan_segment: 'team',
    stripe_price_id: ENV['STRIPE_TEAM_STARTER_PRICE_ID'] || 'price_team_starter',
    amount_cents: 4900,
    interval: 'month',
    max_team_members: 5,
    features: [ 'team_dashboard', 'collaboration', 'email_support' ],
    active: true
  },
  {
    name: 'Team Pro',
    plan_segment: 'team',
    stripe_price_id: ENV['STRIPE_TEAM_PRO_PRICE_ID'] || 'price_team_pro',
    amount_cents: 9900,
    interval: 'month',
    max_team_members: 15,
    features: [ 'team_dashboard', 'collaboration', 'advanced_team_features', 'priority_support' ],
    active: true
  },
  {
    name: 'Team Premium',
    plan_segment: 'team',
    stripe_price_id: ENV['STRIPE_TEAM_PREMIUM_PRICE_ID'] || 'price_team_premium',
    amount_cents: 19900,
    interval: 'month',
    max_team_members: 50,
    features: [ 'team_dashboard', 'collaboration', 'advanced_team_features', 'premium_features', 'priority_support' ],
    active: true
  }
]

team_plans.each do |plan_attrs|
  plan = Plan.find_or_create_by!(name: plan_attrs[:name]) do |p|
    p.attributes = plan_attrs
  end
  puts "Created team plan: #{plan.name}"
end

puts ""

# Create Enterprise Plans (Contact Sales Only)
enterprise_plans = [
  {
    name: 'Enterprise Basic',
    plan_segment: 'enterprise',
    stripe_price_id: ENV['STRIPE_ENTERPRISE_BASIC_PRICE_ID'] || 'price_enterprise_basic',
    amount_cents: 99900, # $999/month - negotiable
    interval: 'month',
    max_team_members: 500,
    features: [ 'all_features', 'dedicated_support', 'sla', 'custom_integrations' ],
    active: true
  },
  {
    name: 'Enterprise Plus',
    plan_segment: 'enterprise',
    stripe_price_id: ENV['STRIPE_ENTERPRISE_PLUS_PRICE_ID'] || 'price_enterprise_plus',
    amount_cents: 299900, # $2999/month - negotiable
    interval: 'month',
    max_team_members: 9999,
    features: [ 'all_features', 'white_glove_support', 'sla', 'custom_integrations', 'on_premise_option' ],
    active: true
  }
]

enterprise_plans.each do |plan_attrs|
  plan = Plan.find_or_create_by!(name: plan_attrs[:name]) do |p|
    p.attributes = plan_attrs
  end
  puts "Created enterprise plan: #{plan.name} (Contact Sales)"
end

puts ""

# Create some inactive and test plans
inactive_plans = [
  {
    name: 'Legacy Individual Plan',
    plan_segment: 'individual',
    stripe_price_id: 'price_legacy_individual',
    amount_cents: 2900,
    interval: 'month',
    features: [ 'legacy_features' ],
    active: false
  },
  {
    name: 'Beta Team Plan',
    plan_segment: 'team',
    stripe_price_id: 'price_beta_team',
    amount_cents: 7900,
    interval: 'month',
    max_team_members: 10,
    features: [ 'beta_features' ],
    active: false
  }
]

inactive_plans.each do |plan_attrs|
  plan = Plan.find_or_create_by!(name: plan_attrs[:name]) do |p|
    p.attributes = plan_attrs
  end
  puts "Created inactive plan: #{plan.name}"
end

puts ""

# Create development users (only in development)
if Rails.env.development?

  # Get plans for assignment
  free_plan = Plan.find_by(name: 'Individual Free')
  pro_plan = Plan.find_by(name: 'Individual Pro')
  premium_plan = Plan.find_by(name: 'Individual Premium')

  # Create super admin
  unless User.exists?(email: 'super@admin.com')
    User.create!(
      email: 'super@admin.com',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      first_name: 'Super',
      last_name: 'Admin',
      system_role: 'super_admin',
      user_type: 'direct',
      status: 'active',
      plan: premium_plan,
      confirmed_at: Time.current
    )
    puts "Created super admin: super@admin.com / Password123! (Premium Plan)"
  end

  # Create site admin
  unless User.exists?(email: 'site@admin.com')
    User.create!(
      email: 'site@admin.com',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      first_name: 'Site',
      last_name: 'Admin',
      system_role: 'site_admin',
      user_type: 'direct',
      status: 'active',
      plan: pro_plan,
      confirmed_at: Time.current
    )
    puts "Created site admin: site@admin.com / Password123! (Pro Plan)"
  end

  # Create direct users with different statuses and plans
  direct_users = [
    {
      email: 'john@example.com',
      first_name: 'John',
      last_name: 'Smith',
      status: 'active',
      plan: free_plan
    },
    {
      email: 'jane@example.com',
      first_name: 'Jane',
      last_name: 'Doe',
      status: 'active',
      plan: pro_plan
    },
    {
      email: 'inactive@example.com',
      first_name: 'Inactive',
      last_name: 'User',
      status: 'inactive',
      plan: free_plan
    },
    {
      email: 'locked@example.com',
      first_name: 'Locked',
      last_name: 'User',
      status: 'locked',
      failed_attempts: 5,
      locked_at: 1.hour.ago,
      plan: premium_plan
    }
  ]

  direct_users.each do |user_attrs|
    unless User.exists?(email: user_attrs[:email])
      User.create!(
        email: user_attrs[:email],
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: user_attrs[:first_name],
        last_name: user_attrs[:last_name],
        system_role: 'user',
        user_type: 'direct',
        status: user_attrs[:status],
        plan: user_attrs[:plan],
        failed_attempts: user_attrs[:failed_attempts] || 0,
        locked_at: user_attrs[:locked_at],
        confirmed_at: Time.current
      )
      puts "Created direct user: #{user_attrs[:email]} / Password123! (#{user_attrs[:status]}, #{user_attrs[:plan].name})"
    end
  end

  # Create team admin users (for team assignment)
  team_admin_users = [
    {
      email: 'teamadmin1@example.com',
      first_name: 'Alice',
      last_name: 'Johnson',
      plan: pro_plan
    },
    {
      email: 'teamadmin2@example.com',
      first_name: 'Bob',
      last_name: 'Wilson',
      plan: pro_plan
    },
    {
      email: 'teamadmin3@example.com',
      first_name: 'Carol',
      last_name: 'Brown',
      plan: free_plan
    }
  ]

  team_admin_users.each do |user_attrs|
    unless User.exists?(email: user_attrs[:email])
      User.create!(
        email: user_attrs[:email],
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: user_attrs[:first_name],
        last_name: user_attrs[:last_name],
        system_role: 'user',
        user_type: 'direct',
        status: 'active',
        plan: user_attrs[:plan],
        confirmed_at: Time.current
      )
      puts "Created team admin candidate: #{user_attrs[:email]} / Password123! (#{user_attrs[:plan].name})"
    end
  end

  puts "\n=== Development Users Created ==="
  puts "Super Admin: super@admin.com / Password123! (Premium Plan)"
  puts "Site Admin:  site@admin.com / Password123! (Pro Plan)"
  puts "Direct Users:"
  puts "  - john@example.com / Password123! (active, Free Plan)"
  puts "  - jane@example.com / Password123! (active, Pro Plan)"
  puts "  - inactive@example.com / Password123! (inactive, Free Plan)"
  puts "  - locked@example.com / Password123! (locked, Premium Plan)"
  puts "Direct User Team Admin Candidates (can be assigned to teams by super admin):"
  puts "  - teamadmin1@example.com / Password123! (Pro Plan)"
  puts "  - teamadmin2@example.com / Password123! (Pro Plan)"
  puts "  - teamadmin3@example.com / Password123! (Free Plan)"
  puts "==================================\n"

  # Create teams with members
  puts "\n=== Creating Teams with Members ==="

  # Note: Teams currently use enum for plan, not Plan model association
  # This will be updated in a future migration

  # Team 1: Acme Corp
  # Create a super admin to act as team creator
  super_admin = User.find_by(email: 'super@admin.com')

  # Use existing direct user as temporary admin, will create proper admin after team exists
  alice_temp = User.find_by(email: 'teamadmin1@example.com')

  if alice_temp && !Team.exists?(name: 'Acme Corp')
    team1 = Team.create!(
      name: 'Acme Corp',
      slug: 'acme-corp',
      admin: alice_temp,
      created_by: super_admin,
      status: 'active',
      plan: 'starter'
    )

    # Now create the actual team admin as an invited user
    unless User.exists?(email: 'alice.admin@acmecorp.com')
      alice = User.create!(
        email: 'alice.admin@acmecorp.com',
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: 'Alice',
        last_name: 'Johnson',
        system_role: 'user',
        user_type: 'invited',
        team: team1,
        team_role: 'admin',
        status: 'active',
        confirmed_at: Time.current
      )
      puts "Created team admin: alice.admin@acmecorp.com / Password123!"

      # Update team to use the new admin
      team1.update!(admin: alice)
    end

    # Create team members for Acme Corp
    acme_members = [
      { email: 'acme1@example.com', first_name: 'David', last_name: 'Miller' },
      { email: 'acme2@example.com', first_name: 'Emma', last_name: 'Davis' },
      { email: 'acme3@example.com', first_name: 'Frank', last_name: 'Garcia' }
    ]

    acme_members.each do |member_attrs|
      User.create!(
        email: member_attrs[:email],
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: member_attrs[:first_name],
        last_name: member_attrs[:last_name],
        system_role: 'user',
        user_type: 'invited',
        team: team1,
        team_role: 'member',
        status: 'active',
        confirmed_at: Time.current
      )
    end

    puts "Created team: Acme Corp with admin alice.admin@acmecorp.com and 3 members (Team Starter plan)"
  end

  # Team 2: Tech Solutions
  bob_temp = User.find_by(email: 'teamadmin2@example.com')

  if bob_temp && !Team.exists?(name: 'Tech Solutions')
    team2 = Team.create!(
      name: 'Tech Solutions',
      slug: 'tech-solutions',
      admin: bob_temp,
      created_by: super_admin,
      status: 'active',
      plan: 'pro'
    )

    # Now create the actual team admin as an invited user
    unless User.exists?(email: 'bob.admin@techsolutions.com')
      bob = User.create!(
        email: 'bob.admin@techsolutions.com',
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: 'Bob',
        last_name: 'Wilson',
        system_role: 'user',
        user_type: 'invited',
        team: team2,
        team_role: 'admin',
        status: 'active',
        confirmed_at: Time.current
      )
      puts "Created team admin: bob.admin@techsolutions.com / Password123!"

      # Update team to use the new admin
      team2.update!(admin: bob)
    end

    # Create team members for Tech Solutions
    tech_members = [
      { email: 'tech1@example.com', first_name: 'Grace', last_name: 'Rodriguez' },
      { email: 'tech2@example.com', first_name: 'Henry', last_name: 'Martinez' },
      { email: 'tech3@example.com', first_name: 'Isabel', last_name: 'Anderson' },
      { email: 'tech4@example.com', first_name: 'Jack', last_name: 'Taylor' }
    ]

    tech_members.each do |member_attrs|
      User.create!(
        email: member_attrs[:email],
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: member_attrs[:first_name],
        last_name: member_attrs[:last_name],
        system_role: 'user',
        user_type: 'invited',
        team: team2,
        team_role: 'member',
        status: 'active',
        confirmed_at: Time.current
      )
    end

    puts "Created team: Tech Solutions with admin bob.admin@techsolutions.com and 4 members (Team Pro plan)"
  end

  # Team 3: Digital Agency (suspended team)
  carol_temp = User.find_by(email: 'teamadmin3@example.com')

  if carol_temp && !Team.exists?(name: 'Digital Agency')
    team3 = Team.create!(
      name: 'Digital Agency',
      slug: 'digital-agency',
      admin: carol_temp,
      created_by: super_admin,
      status: 'suspended',
      plan: 'enterprise'
    )

    # Now create the actual team admin as an invited user
    unless User.exists?(email: 'carol.admin@digitalagency.com')
      carol = User.create!(
        email: 'carol.admin@digitalagency.com',
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: 'Carol',
        last_name: 'Brown',
        system_role: 'user',
        user_type: 'invited',
        team: team3,
        team_role: 'admin',
        status: 'active',
        confirmed_at: Time.current
      )
      puts "Created team admin: carol.admin@digitalagency.com / Password123!"

      # Update team to use the new admin
      team3.update!(admin: carol)
    end

    # Create team members for Digital Agency
    digital_members = [
      { email: 'digital1@example.com', first_name: 'Kevin', last_name: 'White', status: 'inactive' },
      { email: 'digital2@example.com', first_name: 'Laura', last_name: 'Harris', status: 'active' }
    ]

    digital_members.each do |member_attrs|
      User.create!(
        email: member_attrs[:email],
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: member_attrs[:first_name],
        last_name: member_attrs[:last_name],
        system_role: 'user',
        user_type: 'invited',
        team: team3,
        team_role: 'member',
        status: member_attrs[:status] || 'active',
        confirmed_at: Time.current
      )
    end

    puts "Created team: Digital Agency (suspended) with admin carol.admin@digitalagency.com and 2 members (Team Enterprise plan)"
  end

  puts "\n=== Teams Created ==="
  puts "Active Teams:"
  puts "  - Acme Corp (Admin: alice.admin@acmecorp.com, Members: 3, Plan: Team Starter)"
  puts "  - Tech Solutions (Admin: bob.admin@techsolutions.com, Members: 4, Plan: Team Pro)"
  puts "Suspended Teams:"
  puts "  - Digital Agency (Admin: carol.admin@digitalagency.com, Members: 2, Plan: Team Enterprise)"
  puts "\nAll team users can login with password: Password123!"
  puts "\nNote: Team admins are invited users and can only access their team's features."
  puts "==================================\n"

  # TEMPORARILY COMMENTED OUT - Pagination test data causing duplicate emails
  # # Create many additional users for pagination testing
  # puts "\n=== Creating Additional Users for Pagination Testing ==="
  # ... (commented out for now)

  puts "\n=== Plans Summary ==="
  puts "Individual Plans: #{Plan.where(plan_segment: 'individual', active: true).count} active"
  puts "Team Plans: #{Plan.where(plan_segment: 'team', active: true).count} active"
  puts "Enterprise Plans: #{Plan.where(plan_segment: 'enterprise', active: true).count} (Contact Sales)"
  puts "Inactive Plans: #{Plan.where(active: false).count}"
  puts "Total Plans: #{Plan.count}"
  puts "==================================\n"

  # Create test notifications inline instead of loading separate file
  puts "\n=== Creating Test Notifications ==="
  
  # Clear existing notifications for a clean slate
  puts "Clearing existing notifications..."
  Noticed::Notification.destroy_all
  Noticed::Event.destroy_all

  # Find different types of users
  super_admin = User.find_by(system_role: "super_admin")
  site_admin = User.find_by(system_role: "site_admin")
  direct_users = User.direct.active.limit(3)
  team_admins = User.invited.where(team_role: "admin").limit(2)
  team_members = User.invited.where(team_role: "member").limit(3)

  # Create notifications for different user types
  all_users = [ super_admin, site_admin, direct_users, team_admins, team_members ].flatten.compact

  if all_users.any?
    all_users.each_with_index do |user, index|
      next unless user
      
      # Mix of read and unread notifications
      days_ago = rand(0..30)
      
      # 1. Status change notification
      notification = UserStatusNotifier.with(
        user: user,
        old_status: "inactive",
        new_status: "active",
        changed_by: super_admin || User.first
      ).deliver(user)
      
      if days_ago > 7
        user.notifications.last&.mark_as_read!
      end
      
      # 2. Login notification
      locations = [ "New York, NY", "London, UK", "Tokyo, Japan", "Sydney, Australia", "Berlin, Germany" ]
      ip_addresses = [ "192.168.1.1", "10.0.0.1", "172.16.0.1", "203.0.113.0", "198.51.100.0" ]
      
      LoginNotifier.with(
        ip_address: ip_addresses.sample,
        user_agent: "Mozilla/5.0 (#{[ 'Macintosh', 'Windows', 'Linux' ].sample})",
        location: locations.sample
      ).deliver(user)
      
      # 3. Security alerts (critical - always unread)
      if index % 3 == 0
        SecurityAlertNotifier.with(
          alert_type: [ "suspicious_login", "password_reset_attempt", "failed_login_attempts" ].sample,
          ip_address: "185.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}",
          location: "Unknown Location",
          details: "Multiple failed login attempts detected from this IP address"
        ).deliver(user)
      end
      
      # 4. Team-specific notifications
      if user.invited? && user.team
        TeamMemberNotifier.with(
          team: user.team,
          member: user,
          action: [ "added", "removed", "role_changed" ].sample,
          performed_by: user.team.admin
        ).deliver(user)
        
        # Mark some as read
        if rand > 0.5
          user.notifications.last&.mark_as_read!
        end
      end
      
      # 5. Account updates
      AccountUpdateNotifier.with(
        changes: {
          first_name: [ "Old First", user.first_name ],
          last_name: [ "Old Last", user.last_name ]
        }
      ).deliver(user)
      
      # 6. Admin actions (for some users)
      if index % 4 == 0
        AdminActionNotifier.with(
          action: [ "password_reset", "account_unlocked", "email_verified" ].sample,
          admin: super_admin || site_admin || User.first,
          details: { note: "Action performed by administrator", ip_address: "10.0.0.1" }
        ).deliver(user)
      end
    end
    
    # Create some system announcements
    3.times do |i|
      SystemAnnouncementNotifier.with(
        title: "System Update #{i + 1}",
        message: "New features coming #{(i + 1).days.from_now.strftime('%B %d, %Y')}",
        priority: [ "low", "medium", "high" ].sample,
        announcement_type: [ "maintenance", "feature", "general" ].sample
      ).deliver(User.active.limit(5))
    end
    
    puts "\n=== Notification Summary ==="
    puts "Total notification events: #{Noticed::Event.count}"
    puts "Total notifications: #{Noticed::Notification.count}"
    puts "Unread notifications: #{Noticed::Notification.unread.count}"
    puts "Read notifications: #{Noticed::Notification.read.count}"
  else
    puts "No active users found for notifications."
  end

end

# Load notification categories
require_relative "seeds/notification_categories"

puts "\nSeeding complete!"
