# Test data for E2E tests
puts "Creating test users..."

# Create a direct user for login tests
User.find_or_create_by!(email: 'direct@example.com') do |u|
  u.password = 'Password123!'
  u.user_type = 'direct'
  u.system_role = 'user'
  u.status = 'active'
  u.confirmed_at = Time.current
  u.first_name = 'Direct'
  u.last_name = 'User'
end

# Create super admin
User.find_or_create_by!(email: 'super@example.com') do |u|
  u.password = 'Password123!'
  u.user_type = 'direct'
  u.system_role = 'super_admin'
  u.status = 'active'
  u.confirmed_at = Time.current
  u.first_name = 'Super'
  u.last_name = 'Admin'
end

puts "Test users created!"