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

  # Create many additional users for pagination testing
  puts "\n=== Creating Additional Users for Pagination Testing ==="

  # Create 50 direct users with various statuses
  puts "Creating 50 direct users..."
  50.times do |i|
    User.create!(
      email: "direct_user_#{i + 1}@example.com",
      password: 'Password123!',
      password_confirmation: 'Password123!',
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      system_role: 'user',
      user_type: 'direct',
      status: [ 'active', 'active', 'active', 'inactive' ].sample, # 75% active, 25% inactive
      plan: [ free_plan, pro_plan, premium_plan ].sample,
      confirmed_at: Time.current - rand(1..365).days,
      last_activity_at: Time.current - rand(1..30).days,
      created_at: Time.current - rand(1..365).days
    )
  end
  puts "Created 50 direct users"

  # Create 5 more teams with members for pagination
  puts "\nCreating 5 additional teams..."
  5.times do |i|
    team_number = i + 4 # Starting from team 4

    # Create team
    team = Team.create!(
      name: "#{Faker::Company.name} #{team_number}",
      slug: "team-#{team_number}-#{SecureRandom.hex(4)}",
      admin: super_admin, # Temporary admin
      created_by: super_admin,
      status: [ 'active', 'active', 'active', 'suspended' ].sample,
      plan: [ 'starter', 'pro', 'enterprise' ].sample,
      created_at: Time.current - rand(1..365).days
    )

    # Create team admin
    team_admin = User.create!(
      email: "admin#{team_number}@team#{team_number}.com",
      password: 'Password123!',
      password_confirmation: 'Password123!',
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      system_role: 'user',
      user_type: 'invited',
      team: team,
      team_role: 'admin',
      status: 'active',
      confirmed_at: Time.current,
      last_activity_at: Time.current - rand(1..7).days,
      created_at: team.created_at
    )

    team.update!(admin: team_admin)

    # Create team members (3-8 members per team)
    member_count = rand(3..8)
    member_count.times do |j|
      User.create!(
        email: "member#{j + 1}_team#{team_number}@example.com",
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        system_role: 'user',
        user_type: 'invited',
        team: team,
        team_role: 'member',
        status: [ 'active', 'active', 'active', 'inactive' ].sample,
        confirmed_at: Time.current,
        last_activity_at: Time.current - rand(1..30).days,
        created_at: team.created_at + rand(1..30).days
      )
    end

    puts "Created team: #{team.name} with #{member_count} members"
  end

  # Create 3 enterprise groups with members
  puts "\nCreating 3 enterprise groups..."
  3.times do |i|
    enterprise_number = i + 1

    enterprise_plan = Plan.find_by(plan_segment: 'enterprise', active: true)

    # Create enterprise group
    enterprise_group = EnterpriseGroup.create!(
      name: "#{Faker::Company.name} Enterprise #{enterprise_number}",
      slug: "enterprise-#{enterprise_number}-#{SecureRandom.hex(4)}",
      created_by: super_admin,
      plan: enterprise_plan,
      status: [ 'active', 'active', 'suspended' ].sample,
      max_members: 100,
      created_at: Time.current - rand(1..365).days
    )

    # Create enterprise admin
    enterprise_admin = User.create!(
      email: "admin@enterprise#{enterprise_number}.com",
      password: 'Password123!',
      password_confirmation: 'Password123!',
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      system_role: 'user',
      user_type: 'enterprise',
      enterprise_group: enterprise_group,
      enterprise_group_role: 'admin',
      status: 'active',
      confirmed_at: Time.current,
      last_activity_at: Time.current - rand(1..7).days,
      created_at: enterprise_group.created_at
    )

    enterprise_group.update!(admin: enterprise_admin)

    # Create enterprise members (10-20 members per group)
    member_count = rand(10..20)
    member_count.times do |j|
      User.create!(
        email: "emp#{j + 1}_enterprise#{enterprise_number}@example.com",
        password: 'Password123!',
        password_confirmation: 'Password123!',
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        system_role: 'user',
        user_type: 'enterprise',
        enterprise_group: enterprise_group,
        enterprise_group_role: 'member',
        status: [ 'active', 'active', 'active', 'inactive' ].sample,
        confirmed_at: Time.current,
        last_activity_at: Time.current - rand(1..30).days,
        created_at: enterprise_group.created_at + rand(1..30).days
      )
    end

    puts "Created enterprise group: #{enterprise_group.name} with #{member_count} members"
  end

  # Create pending invitations for testing pagination
  puts "\nCreating pending invitations..."

  # Team invitations
  Team.active.limit(3).each do |team|
    5.times do |i|
      Invitation.create!(
        team: team,
        invitable: team,
        invitation_type: 'team',
        email: "pending_invite_#{i + 1}_#{team.slug}@example.com",
        role: [ 'member', 'member', 'admin' ].sample,
        token: SecureRandom.urlsafe_base64(32),
        invited_by: team.admin,
        expires_at: 7.days.from_now,
        created_at: Time.current - rand(1..5).days
      )
    end
  end
  puts "Created team invitations"

  # Enterprise invitations
  EnterpriseGroup.active.limit(2).each do |enterprise|
    3.times do |i|
      Invitation.create!(
        invitable: enterprise,
        invitation_type: 'enterprise',
        email: "pending_enterprise_#{i + 1}_#{enterprise.slug}@example.com",
        role: [ 'member', 'member', 'admin' ].sample,
        token: SecureRandom.urlsafe_base64(32),
        invited_by: enterprise.admin,
        expires_at: 7.days.from_now,
        created_at: Time.current - rand(1..5).days
      )
    end
  end
  puts "Created enterprise invitations"

  puts "\n=== Pagination Test Data Created ==="
  puts "Total Users: #{User.count}"
  puts "- Direct Users: #{User.direct.count}"
  puts "- Team Members: #{User.invited.count}"
  puts "- Enterprise Users: #{User.enterprise.count}"
  puts "Total Teams: #{Team.count}"
  puts "Total Enterprise Groups: #{EnterpriseGroup.count}"
  puts "Total Pending Invitations: #{Invitation.pending.count}"
  puts "==================================\n"

  puts "\n=== Plans Summary ==="
  puts "Individual Plans: #{Plan.where(plan_segment: 'individual', active: true).count} active"
  puts "Team Plans: #{Plan.where(plan_segment: 'team', active: true).count} active"
  puts "Enterprise Plans: #{Plan.where(plan_segment: 'enterprise', active: true).count} (Contact Sales)"
  puts "Inactive Plans: #{Plan.where(active: false).count}"
  puts "Total Plans: #{Plan.count}"
  puts "==================================\n"

end

puts "\nSeeding complete!"
