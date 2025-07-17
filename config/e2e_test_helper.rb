# E2E Test Helper for Playwright tests
# This file configures the Rails environment for E2E tests with proper database cleaning

require 'database_cleaner/active_record'

# Configure DatabaseCleaner for E2E tests
DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.allow_production = false

# Use truncation strategy for E2E tests (not transactions)
# This ensures data is visible across different processes
DatabaseCleaner.strategy = :truncation

# Tables to preserve (don't truncate these)
DatabaseCleaner.strategy = :truncation, {
  except: %w[ar_internal_metadata schema_migrations]
}

# Helper module for E2E test data setup
module E2ETestHelper
  class << self
    # Clean the database before each test suite
    def clean_database
      puts "🧹 Cleaning E2E test database..."
      DatabaseCleaner.clean_with :truncation
    end

    # Start a cleaning strategy (call before test)
    def start_clean
      DatabaseCleaner.start
    end

    # Clean the database (call after test)
    def clean
      DatabaseCleaner.clean
    end

    # Setup basic test data that all E2E tests need
    def setup_basic_data
      puts "🌱 Setting up basic E2E test data..."
      
      # Ensure we're in the e2e_test environment
      unless Rails.env.e2e_test?
        raise "E2E tests must run in e2e_test environment. Current: #{Rails.env}"
      end

      # Load shared test data module
      require_relative '../test/support/shared_test_data'
      
      # Use shared test data for consistency
      SharedTestData.create_test_plans
      SharedTestData.create_notification_categories
      
      puts "✅ Basic E2E test data setup complete"
    end

  end
end

# Monkey patch Rails to recognize e2e_test environment
module Rails
  class << self
    def e2e_test?
      env == 'e2e_test'
    end
  end
end