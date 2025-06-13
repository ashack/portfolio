namespace :auth do
  desc "Test authentication flow"
  task test: :environment do
    puts "Testing Authentication Flow..."
    puts "=" * 50

    # Check if user exists
    user = User.find_by(email: "super@admin.com")
    if user
      puts "✓ Test user found: #{user.email}"
      puts "  - Status: #{user.status}"
      puts "  - Confirmed: #{user.confirmed_at.present? ? 'Yes' : 'No'}"
      puts "  - Can sign in: #{user.can_sign_in? ? 'Yes' : 'No'}"
      puts "  - Active for auth: #{user.active_for_authentication? ? 'Yes' : 'No'}"
    else
      puts "✗ No test user found"
      puts "Creating test user..."
      user = User.create!(
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "Test",
        last_name: "User",
        status: "active",
        user_type: "direct",
        confirmed_at: Time.current
      )
      puts "✓ Test user created: #{user.email}"
    end

    puts "\nSession Configuration:"
    puts "  - Store: #{Rails.application.config.session_store}"
    puts "  - Key: #{Rails.application.config.session_options[:key] rescue 'default'}"

    puts "\nAuthentication Modules:"
    puts "  - Devise modules: #{User.devise_modules.join(', ')}"

    puts "\nTest complete!"
  end
end
