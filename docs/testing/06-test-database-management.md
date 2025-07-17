# Test Database Management

## Overview

This document explains how test databases are managed for both Rails tests and Playwright E2E tests, ensuring complete isolation and preventing conflicts.

## Architecture

### Separate Databases

1. **Rails Tests**: `storage/test.sqlite3`
   - Used by Minitest/Rails tests
   - Supports parallel execution with numbered databases
   - Uses transactional fixtures for fast cleanup

2. **E2E Tests**: `storage/e2e_test.sqlite3`
   - Dedicated database for Playwright tests
   - Uses DatabaseCleaner with truncation strategy
   - Complete isolation from Rails tests

### Key Components

1. **DatabaseCleaner**: Manages database cleanup between tests
2. **SharedTestData**: Ensures consistent test data across both test types
3. **E2ETestHelper**: Configures database cleaning for E2E tests
4. **Rake Tasks**: Automate database setup and maintenance

## Configuration

### Environment Setup

```yaml
# config/database.yml
e2e_test:
  <<: *default
  database: storage/e2e_test.sqlite3
```

```env
# .env.test
TEST_DATABASE_URL=sqlite3:storage/e2e_test.sqlite3
RAILS_ENV=e2e_test
```

### Playwright Configuration

```typescript
// playwright.config.ts
webServer: {
  command: 'RAILS_ENV=e2e_test bundle exec rails server -p 3001',
  port: 3001,
  env: {
    RAILS_ENV: 'e2e_test',
    DATABASE_URL: process.env.TEST_DATABASE_URL,
  },
}
```

## Usage

### Rake Tasks

```bash
# E2E Database Management
rails db:e2e:create      # Create E2E test database
rails db:e2e:migrate     # Run migrations
rails db:e2e:seed        # Seed with test data
rails db:e2e:prepare     # Complete setup (create, migrate, seed)
rails db:e2e:reset       # Drop and recreate
rails db:e2e:clean       # Truncate all tables

# Convenience Tasks
rails e2e:prepare        # Prepare E2E environment
rails e2e:run           # Setup and run E2E tests

# Combined Management
rails db:test:reset_all  # Reset both test databases
rails db:test:status     # Show database status
```

### Running Tests

```bash
# Rails Tests (use regular test database)
bundle exec rails test

# E2E Tests (use dedicated e2e database)
./run_e2e_test.sh
# or
npm run e2e

# Run specific E2E test
npm run e2e auth/login.spec.ts
```

## Shared Test Data

The `SharedTestData` module ensures consistency between test types:

```ruby
# test/support/shared_test_data.rb
SharedTestData.create_test_users      # Standard test users
SharedTestData.create_test_plans      # Subscription plans
SharedTestData.create_test_team       # Test team with members
```

## DatabaseCleaner Configuration

### E2E Tests

```ruby
# config/e2e_test_helper.rb
DatabaseCleaner.strategy = :truncation, {
  except: %w[ar_internal_metadata schema_migrations]
}
```

### Why Truncation?

- E2E tests run in separate process
- Cannot use transactional rollback
- Data must be visible across processes
- Truncation ensures complete cleanup

## Best Practices

1. **Always use rake tasks** for database setup
   ```bash
   rails db:e2e:prepare  # Before running E2E tests
   ```

2. **Check database status** before debugging
   ```bash
   rails db:test:status
   ```

3. **Use shared test data** for consistency
   ```ruby
   require 'test/support/shared_test_data'
   SharedTestData.setup_test_environment
   ```

4. **Clean between test runs** if needed
   ```bash
   rails db:e2e:clean
   ```

## Troubleshooting

### Common Issues

1. **"Database not found" error**
   ```bash
   rails db:e2e:create
   ```

2. **"Table doesn't exist" error**
   ```bash
   rails db:e2e:migrate
   ```

3. **Stale test data**
   ```bash
   rails db:e2e:reset
   ```

4. **Port conflicts**
   - E2E tests use port 3001
   - Rails tests use default port 3000

### Debugging

```bash
# Check if databases exist
ls -la storage/*.sqlite3

# View E2E test logs
tail -f log/e2e_test.log

# Run E2E server manually
RAILS_ENV=e2e_test rails server -p 3001
```

## Benefits

1. **Complete Isolation**: No conflicts between test types
2. **Parallel Execution**: Both test suites can run simultaneously
3. **Consistent Data**: Shared fixtures ensure reliability
4. **Fast Cleanup**: Optimized strategies for each test type
5. **Easy Maintenance**: Clear separation of concerns

## Migration from Single Database

If migrating from a single test database:

1. Update database.yml with e2e_test configuration
2. Update .env.test with new database path and SECRET_KEY_BASE
3. Run `rails db:e2e:prepare`
4. Update Playwright config to use e2e_test environment
5. Update test scripts to use new rake tasks

## Implementation Status

✅ **Successfully Implemented** (January 2025)

The test database separation has been successfully implemented with the following components:

1. **Separate Databases**: Rails tests use `test.sqlite3`, E2E tests use `e2e_test.sqlite3`
2. **DatabaseCleaner Integration**: Proper cleanup between test runs
3. **SharedTestData Module**: Consistent test fixtures across both test types
4. **Rake Tasks**: Full suite of database management commands
5. **E2E Tests**: All 115 tests passing with proper isolation

### Key Configuration Files

- `config/database.yml` - E2E database configuration
- `.env.test` - Environment variables including SECRET_KEY_BASE
- `config/e2e_test_helper.rb` - DatabaseCleaner setup
- `test/support/shared_test_data.rb` - Shared test fixtures
- `lib/tasks/e2e.rake` - Database management tasks

## CI/CD Integration

```yaml
# Example GitHub Actions
- name: Setup E2E Database
  run: bundle exec rails db:e2e:prepare
  
- name: Run E2E Tests
  run: npm run e2e
```

## Performance Considerations

- SQLite is fast for test databases
- Truncation is slower than transactions but necessary for E2E
- Consider using `:deletion` strategy for specific tables
- Database pooling is configured for concurrent access

## Future Enhancements

1. PostgreSQL support for production-like testing
2. Database snapshots for faster restoration
3. Automatic cleanup scheduling
4. Test data factories with FactoryBot
5. Database performance monitoring