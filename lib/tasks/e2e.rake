# Rake tasks for E2E test database management

namespace :db do
  namespace :e2e do
    desc "Create E2E test database"
    task create: :environment do
      # Switch to e2e_test environment temporarily
      original_env = Rails.env
      Rails.env = 'e2e_test'
      
      puts "Creating E2E test database..."
      Rake::Task['db:create'].invoke
      
      Rails.env = original_env
      puts "✅ E2E test database created"
    end

    desc "Migrate E2E test database"
    task migrate: :environment do
      original_env = Rails.env
      Rails.env = 'e2e_test'
      
      puts "Migrating E2E test database..."
      ActiveRecord::Base.establish_connection(:e2e_test)
      ActiveRecord::MigrationContext.new('db/migrate').migrate
      
      Rails.env = original_env
      puts "✅ E2E test database migrated"
    end

    desc "Prepare E2E test database (create, migrate, and seed)"
    task prepare: :environment do
      Rake::Task['db:e2e:create'].invoke rescue nil # Ignore if already exists
      Rake::Task['db:e2e:migrate'].invoke
      Rake::Task['db:e2e:seed'].invoke
    end

    desc "Seed E2E test database with basic data"
    task seed: :environment do
      original_env = Rails.env
      Rails.env = 'e2e_test'
      
      puts "Seeding E2E test database..."
      
      # Load Rails environment with e2e_test
      require_relative '../../config/e2e_test_helper'
      
      # Clean and setup basic data
      E2ETestHelper.clean_database
      E2ETestHelper.setup_basic_data
      
      Rails.env = original_env
      puts "✅ E2E test database seeded"
    end

    desc "Drop E2E test database"
    task drop: :environment do
      original_env = Rails.env
      Rails.env = 'e2e_test'
      
      puts "Dropping E2E test database..."
      Rake::Task['db:drop'].invoke
      
      Rails.env = original_env
      puts "✅ E2E test database dropped"
    end

    desc "Reset E2E test database (drop, create, migrate, seed)"
    task reset: :environment do
      Rake::Task['db:e2e:drop'].invoke rescue nil
      Rake::Task['db:e2e:prepare'].invoke
    end

    desc "Clean E2E test database (truncate all tables)"
    task clean: :environment do
      require_relative '../../config/e2e_test_helper'
      
      puts "Cleaning E2E test database..."
      E2ETestHelper.clean_database
      puts "✅ E2E test database cleaned"
    end
  end

  namespace :test do
    desc "Reset all test databases (Rails test + E2E test)"
    task reset_all: :environment do
      puts "Resetting all test databases..."
      
      # Reset Rails test database
      puts "\n🔧 Resetting Rails test database..."
      Rake::Task['db:test:prepare'].invoke
      
      # Reset E2E test database
      puts "\n🔧 Resetting E2E test database..."
      Rake::Task['db:e2e:reset'].invoke
      
      puts "\n✅ All test databases reset successfully"
    end

    desc "Show test database status"
    task status: :environment do
      puts "\n📊 Test Database Status:"
      puts "=" * 50
      
      # Rails test database
      test_db = Rails.root.join('storage/test.sqlite3')
      if File.exist?(test_db)
        size = (File.size(test_db) / 1024.0 / 1024.0).round(2)
        puts "Rails Test DB: ✅ Exists (#{size} MB)"
        
        # Check for parallel test databases
        parallel_dbs = Dir[Rails.root.join('storage/test.sqlite3-*')]
        if parallel_dbs.any?
          puts "  Parallel DBs: #{parallel_dbs.count} found"
        end
      else
        puts "Rails Test DB: ❌ Not found"
      end
      
      # E2E test database
      e2e_db = Rails.root.join('storage/e2e_test.sqlite3')
      if File.exist?(e2e_db)
        size = (File.size(e2e_db) / 1024.0 / 1024.0).round(2)
        puts "E2E Test DB:   ✅ Exists (#{size} MB)"
      else
        puts "E2E Test DB:   ❌ Not found"
      end
      
      puts "=" * 50
    end
  end
end

# Convenience tasks
desc "Prepare E2E test environment"
task 'e2e:prepare' => 'db:e2e:prepare'

desc "Run E2E tests with database setup"
task 'e2e:run' => ['db:e2e:prepare'] do
  puts "\n🧪 Running E2E tests..."
  system('npm run e2e')
end