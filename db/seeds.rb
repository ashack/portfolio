# Create Individual Plans
individual_plans = [
  {
    name: 'Individual Free',
    plan_type: 'individual',
    amount_cents: 0,
    features: ['basic_dashboard', 'email_support']
  },
  {
    name: 'Individual Pro',
    plan_type: 'individual',
    stripe_price_id: ENV['STRIPE_INDIVIDUAL_PRO_PRICE_ID'] || 'price_individual_pro',
    amount_cents: 1900,
    interval: 'month',
    features: ['basic_dashboard', 'advanced_features', 'priority_support']
  },
  {
    name: 'Individual Premium',
    plan_type: 'individual',
    stripe_price_id: ENV['STRIPE_INDIVIDUAL_PREMIUM_PRICE_ID'] || 'price_individual_premium',
    amount_cents: 4900,
    interval: 'month',
    features: ['basic_dashboard', 'advanced_features', 'premium_features', 'phone_support']
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
    features: ['team_dashboard', 'collaboration', 'email_support']
  },
  {
    name: 'Team Pro',
    plan_type: 'team',
    stripe_price_id: ENV['STRIPE_TEAM_PRO_PRICE_ID'] || 'price_team_pro',
    amount_cents: 9900,
    interval: 'month',
    max_team_members: 15,
    features: ['team_dashboard', 'collaboration', 'advanced_team_features', 'priority_support']
  },
  {
    name: 'Team Enterprise',
    plan_type: 'team',
    stripe_price_id: ENV['STRIPE_TEAM_ENTERPRISE_PRICE_ID'] || 'price_team_enterprise',
    amount_cents: 19900,
    interval: 'month',
    max_team_members: 100,
    features: ['team_dashboard', 'collaboration', 'advanced_team_features', 'enterprise_features', 'phone_support']
  }
]

team_plans.each do |plan_attrs|
  Plan.find_or_create_by!(name: plan_attrs[:name]) do |plan|
    plan.attributes = plan_attrs
  end
end

# Create default super admin (only in development)
if Rails.env.development? && !User.exists?(system_role: 'super_admin')
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

puts "Seeding complete!"
