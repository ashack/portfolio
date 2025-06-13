# Create Individual Plans
individual_plans = [
  {
    name: 'Individual Free',
    plan_type: 'individual',
    amount_cents: 0,
    features: [ 'basic_dashboard', 'email_support' ]
  },
  {
    name: 'Individual Pro',
    plan_type: 'individual',
    stripe_price_id: ENV['STRIPE_INDIVIDUAL_PRO_PRICE_ID'] || 'price_individual_pro',
    amount_cents: 1900,
    interval: 'month',
    features: [ 'basic_dashboard', 'advanced_features', 'priority_support' ]
  },
  {
    name: 'Individual Premium',
    plan_type: 'individual',
    stripe_price_id: ENV['STRIPE_INDIVIDUAL_PREMIUM_PRICE_ID'] || 'price_individual_premium',
    amount_cents: 4900,
    interval: 'month',
    features: [ 'basic_dashboard', 'advanced_features', 'premium_features', 'phone_support' ]
  }
]

individual_plans.each do |plan_attrs|
  Plan.find_or_create_by!(name: plan_attrs[:name]) do |plan|
    plan.attributes = plan_attrs
  end
end

# Create Team Plans
team_plans = [
  {
    name: 'Team Starter',
    plan_type: 'team',
    stripe_price_id: ENV['STRIPE_TEAM_STARTER_PRICE_ID'] || 'price_team_starter',
    amount_cents: 4900,
    interval: 'month',
    max_team_members: 5,
    features: [ 'team_dashboard', 'collaboration', 'email_support' ]
  },
  {
    name: 'Team Pro',
    plan_type: 'team',
    stripe_price_id: ENV['STRIPE_TEAM_PRO_PRICE_ID'] || 'price_team_pro',
    amount_cents: 9900,
    interval: 'month',
    max_team_members: 15,
    features: [ 'team_dashboard', 'collaboration', 'advanced_team_features', 'priority_support' ]
  },
  {
    name: 'Team Enterprise',
    plan_type: 'team',
    stripe_price_id: ENV['STRIPE_TEAM_ENTERPRISE_PRICE_ID'] || 'price_team_enterprise',
    amount_cents: 19900,
    interval: 'month',
    max_team_members: 100,
    features: [ 'team_dashboard', 'collaboration', 'advanced_team_features', 'enterprise_features', 'phone_support' ]
  }
]

team_plans.each do |plan_attrs|
  Plan.find_or_create_by!(name: plan_attrs[:name]) do |plan|
    plan.attributes = plan_attrs
  end
end

# Create development users (only in development)
if Rails.env.development?

  # Create super admin
  unless User.exists?(email: 'super@admin.com')
    User.create!(
      email: 'super@admin.com',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Super',
      last_name: 'Admin',
      system_role: 'super_admin',
      user_type: 'direct',
      status: 'active',
      confirmed_at: Time.current
    )
    puts "Created super admin: super@admin.com / password123"
  end

  # Create site admin
  unless User.exists?(email: 'site@admin.com')
    User.create!(
      email: 'site@admin.com',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Site',
      last_name: 'Admin',
      system_role: 'site_admin',
      user_type: 'direct',
      status: 'active',
      confirmed_at: Time.current
    )
    puts "Created site admin: site@admin.com / password123"
  end

  # Create direct users with different statuses
  direct_users = [
    {
      email: 'john@example.com',
      first_name: 'John',
      last_name: 'Smith',
      status: 'active'
    },
    {
      email: 'jane@example.com',
      first_name: 'Jane',
      last_name: 'Doe',
      status: 'active'
    },
    {
      email: 'inactive@example.com',
      first_name: 'Inactive',
      last_name: 'User',
      status: 'inactive'
    },
    {
      email: 'locked@example.com',
      first_name: 'Locked',
      last_name: 'User',
      status: 'locked',
      failed_attempts: 5,
      locked_at: 1.hour.ago
    }
  ]

  direct_users.each do |user_attrs|
    unless User.exists?(email: user_attrs[:email])
      User.create!(
        email: user_attrs[:email],
        password: 'password123',
        password_confirmation: 'password123',
        first_name: user_attrs[:first_name],
        last_name: user_attrs[:last_name],
        system_role: 'user',
        user_type: 'direct',
        status: user_attrs[:status],
        failed_attempts: user_attrs[:failed_attempts] || 0,
        locked_at: user_attrs[:locked_at],
        confirmed_at: Time.current
      )
      puts "Created direct user: #{user_attrs[:email]} / password123 (#{user_attrs[:status]})"
    end
  end

  # Create team admin users (for team assignment)
  team_admin_users = [
    {
      email: 'teamadmin1@example.com',
      first_name: 'Alice',
      last_name: 'Johnson'
    },
    {
      email: 'teamadmin2@example.com',
      first_name: 'Bob',
      last_name: 'Wilson'
    },
    {
      email: 'teamadmin3@example.com',
      first_name: 'Carol',
      last_name: 'Brown'
    }
  ]

  team_admin_users.each do |user_attrs|
    unless User.exists?(email: user_attrs[:email])
      User.create!(
        email: user_attrs[:email],
        password: 'password123',
        password_confirmation: 'password123',
        first_name: user_attrs[:first_name],
        last_name: user_attrs[:last_name],
        system_role: 'user',
        user_type: 'direct',
        status: 'active',
        confirmed_at: Time.current
      )
      puts "Created team admin candidate: #{user_attrs[:email]} / password123"
    end
  end

  puts "\n=== Development Users Created ==="
  puts "Super Admin: super@admin.com / password123"
  puts "Site Admin:  site@admin.com / password123"
  puts "Direct Users:"
  puts "  - john@example.com / password123 (active)"
  puts "  - jane@example.com / password123 (active)"
  puts "  - inactive@example.com / password123 (inactive)"
  puts "  - locked@example.com / password123 (locked)"
  puts "Team Admin Candidates:"
  puts "  - teamadmin1@example.com / password123 (ready for team assignment)"
  puts "  - teamadmin2@example.com / password123 (ready for team assignment)"
  puts "  - teamadmin3@example.com / password123 (ready for team assignment)"
  puts "\nNote: Team admin candidates can be assigned to teams by the super admin."
  puts "==================================\n"

  # Create teams with members
  puts "\n=== Creating Teams with Members ==="

  # Team 1: Acme Corp
  alice = User.find_by(email: 'teamadmin1@example.com')
  if alice && !Team.exists?(name: 'Acme Corp')
    team1 = Team.create!(
      name: 'Acme Corp',
      slug: 'acme-corp',
      admin: alice,
      created_by: alice,
      status: 'active'
    )

    # Update Alice to be a team admin
    alice.update!(user_type: 'invited', team: team1, team_role: 'admin')

    # Create team members for Acme Corp
    acme_members = [
      { email: 'acme1@example.com', first_name: 'David', last_name: 'Miller' },
      { email: 'acme2@example.com', first_name: 'Emma', last_name: 'Davis' },
      { email: 'acme3@example.com', first_name: 'Frank', last_name: 'Garcia' }
    ]

    acme_members.each do |member_attrs|
      User.create!(
        email: member_attrs[:email],
        password: 'password123',
        password_confirmation: 'password123',
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

    puts "Created team: Acme Corp with admin teamadmin1@example.com and 3 members"
  end

  # Team 2: Tech Solutions
  bob = User.find_by(email: 'teamadmin2@example.com')
  if bob && !Team.exists?(name: 'Tech Solutions')
    team2 = Team.create!(
      name: 'Tech Solutions',
      slug: 'tech-solutions',
      admin: bob,
      created_by: bob,
      status: 'active'
    )

    # Update Bob to be a team admin
    bob.update!(user_type: 'invited', team: team2, team_role: 'admin')

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
        password: 'password123',
        password_confirmation: 'password123',
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

    puts "Created team: Tech Solutions with admin teamadmin2@example.com and 4 members"
  end

  # Team 3: Digital Agency (suspended team)
  carol = User.find_by(email: 'teamadmin3@example.com')
  if carol && !Team.exists?(name: 'Digital Agency')
    team3 = Team.create!(
      name: 'Digital Agency',
      slug: 'digital-agency',
      admin: carol,
      created_by: carol,
      status: 'suspended'
    )

    # Update Carol to be a team admin
    carol.update!(user_type: 'invited', team: team3, team_role: 'admin')

    # Create team members for Digital Agency
    digital_members = [
      { email: 'digital1@example.com', first_name: 'Kevin', last_name: 'White', status: 'inactive' },
      { email: 'digital2@example.com', first_name: 'Laura', last_name: 'Harris', status: 'active' }
    ]

    digital_members.each do |member_attrs|
      User.create!(
        email: member_attrs[:email],
        password: 'password123',
        password_confirmation: 'password123',
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

    puts "Created team: Digital Agency (suspended) with admin teamadmin3@example.com and 2 members"
  end

  puts "\n=== Teams Created ==="
  puts "Active Teams:"
  puts "  - Acme Corp (Admin: teamadmin1@example.com, Members: 3)"
  puts "  - Tech Solutions (Admin: teamadmin2@example.com, Members: 4)"
  puts "Suspended Teams:"
  puts "  - Digital Agency (Admin: teamadmin3@example.com, Members: 2)"
  puts "\nAll team users can login with password: password123"
  puts "==================================\n"

end

puts "Seeding complete!"
