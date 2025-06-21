ENV["RAILS_ENV"] ||= "test"

# Configure SimpleCov for test coverage
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter %r{^/test/}
  add_filter %r{^/config/}
  add_filter %r{^/vendor/}

  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Helpers", "app/helpers"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Services", "app/services"
  add_group "Policies", "app/policies"
  add_group "Validators", "app/validators"

  # Set minimum coverage goals (can be adjusted as project grows)
  # minimum_coverage 90
  # minimum_coverage_by_file 80
end

require_relative "../config/environment"
require "rails/test_help"
require "minitest/rails"
require "minitest/reporters"

# Configure Minitest reporters for better test output
Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new(color: true),
  Minitest::Reporters::ProgressReporter.new
]

module ActiveSupport
  class TestCase
    # Skip manual tests that require server to be running
    self.test_order = :random

    # Filter out manual test files
    def self.file_fixture_path
      Rails.root.join("test", "fixtures", "files")
    end
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Include Devise test helpers
    include Devise::Test::IntegrationHelpers

    # Helper method to sign in a user
    def sign_in_as(user)
      sign_in user
    end

    # Helper method to create and sign in a user with specific attributes
    def sign_in_with(attributes = {})
      user = User.create!(
        email: attributes[:email] || "test@example.com",
        password: attributes[:password] || "Password123!",
        first_name: attributes[:first_name] || "Test",
        last_name: attributes[:last_name] || "User",
        system_role: attributes[:system_role] || "user",
        user_type: attributes[:user_type] || "direct",
        status: attributes[:status] || "active",
        confirmed_at: Time.current,
        team: attributes[:team],
        team_role: attributes[:team_role],
        enterprise_group: attributes[:enterprise_group],
        enterprise_group_role: attributes[:enterprise_group_role]
      )
      sign_in user
      user
    end
  end
end

# Configure Capybara for system tests
require "capybara/rails"
require "capybara/minitest"

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  # Reset sessions and driver between tests
  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
