# Verify onboarding user and plans
user = User.find_by(email: "onboarding@example.com")
puts "\n=== User Status ==="
puts "Email: #{user.email}"
puts "Type: #{user.user_type}"
puts "Status: #{user.status}"
puts "Confirmed: #{user.confirmed?}"
puts "Has Plan: #{user.plan_id.present?}"
puts "Onboarding Completed: #{user.onboarding_completed}"
puts "Onboarding Step: #{user.onboarding_step}"

puts "\n=== Available Plans ==="
Plan.available_for_signup.each do |plan|
  puts "- #{plan.name} (#{plan.plan_segment}) - $#{plan.amount_cents / 100}"
end

puts "\n=== Testing Onboarding Logic ==="
puts "Should redirect to onboarding? #{user.direct? && \!user.onboarding_completed? && user.plan_id.nil?}"
