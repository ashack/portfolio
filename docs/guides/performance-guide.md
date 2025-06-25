# Performance Optimizations Guide

This document describes the performance optimizations implemented in the Rails SaaS application to ensure scalability and responsiveness.

## Overview

The application implements several performance optimization strategies aligned with Rails best practices:

1. **Background Job Processing** - Offloads heavy operations from request cycle
2. **Caching Strategy** - Reduces database queries and improves response times
3. **Database Indexing** - Optimizes query performance
4. **Query Optimization** - Prevents N+1 queries and optimizes data fetching

## 1. Background Job Processing

### Activity Tracking

Previously, user activity was tracked synchronously on every request:

```ruby
# OLD: Synchronous database update on every request
def track_user_activity
  if current_user
    current_user.update_column(:last_activity_at, Time.current)
  end
end
```

This has been replaced with an asynchronous background job system:

#### Implementation

**`app/jobs/track_user_activity_job.rb`**
```ruby
class TrackUserActivityJob < ApplicationJob
  queue_as :low_priority
  ACTIVITY_UPDATE_INTERVAL = 5.minutes

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Only update if last activity was more than 5 minutes ago
    last_activity = user.last_activity_at
    return if last_activity && last_activity > ACTIVITY_UPDATE_INTERVAL.ago

    user.update_column(:last_activity_at, Time.current)
  end
end
```

**`app/controllers/concerns/activity_tracking.rb`**
```ruby
module ActivityTracking
  extend ActiveSupport::Concern

  included do
    before_action :track_user_activity_async
  end

  private

  def track_user_activity_async
    return unless current_user

    # Use Redis to prevent duplicate jobs
    cache_key = "user_activity:#{current_user.id}"
    return if Rails.cache.read(cache_key)

    # Set cache flag for 1 minute
    Rails.cache.write(cache_key, true, expires_in: 1.minute)

    # Queue background job
    TrackUserActivityJob.perform_later(current_user.id)
  end
end
```

### Benefits

- Removes database write from request cycle
- Prevents duplicate activity updates
- Reduces database load
- Improves request response time

## 2. Caching Strategy

### Model-Level Caching

The application implements caching for frequently accessed data:

#### Team Slug Caching

**`app/models/team.rb`**
```ruby
# Cache-friendly lookup by slug
def self.find_by_slug!(slug)
  Rails.cache.fetch(["team-by-slug", slug], expires_in: 1.hour) do
    find_by!(slug: slug)
  end
end

# Cache slug for URL generation
def to_param
  Rails.cache.fetch(["team-slug", id, updated_at]) { slug }
end

# Clear caches on update
after_commit :clear_caches

def clear_caches
  Rails.cache.delete(["team-slug", id, updated_at])
  Rails.cache.delete(["team-by-slug", slug])
  Rails.cache.delete(["team-by-slug", slug_previously_was]) if saved_change_to_slug?
end
```

#### Enterprise Group Caching

Similar caching is implemented for `EnterpriseGroup` model with the same pattern.

### View-Level Caching

Fragment caching is implemented in dashboard views:

**`app/views/teams/dashboard/index.html.erb`**
```erb
<!-- Cache welcome section -->
<% cache ["team-dashboard-welcome", @team, @team.updated_at, current_user.team_role] do %>
  <!-- Welcome content -->
<% end %>

<!-- Cache team stats with member updates -->
<% cache ["team-dashboard-stats", @team, @team.updated_at, @team_members.maximum(:updated_at)] do %>
  <!-- Stats content -->
<% end %>

<!-- Cache activity with 5-minute expiration -->
<% cache ["team-dashboard-activity", @team, @recent_activities.maximum(:last_activity_at)], expires_in: 5.minutes do %>
  <!-- Activity content -->
<% end %>
```

### Cacheable Concern

A reusable concern for cache management:

**`app/models/concerns/cacheable.rb`**
```ruby
module Cacheable
  extend ActiveSupport::Concern

  class_methods do
    def cache_key_for_collection(scope = :all)
      max_updated_at = maximum(:updated_at)&.utc&.to_fs(:number) || "0"
      count = send(scope).count
      "#{model_name.cache_key}/collection-#{scope}-#{count}-#{max_updated_at}"
    end
  end

  def cache_key_with_version
    "#{model_name.cache_key}/#{id}-#{updated_at.utc.to_fs(:number)}"
  end
end
```

## 3. Database Indexing

Comprehensive indexes have been added to optimize query performance:

### Index Strategy

1. **Activity Tracking**
   - `index_users_on_status_and_activity` - For filtering active users by activity
   - `index_users_on_last_activity_at` - For sorting by activity

2. **Team Queries**
   - `index_users_on_team_and_status` - For team member listings
   - `index_teams_on_slug_and_status` - For slug lookups with status check
   - `index_teams_on_status_and_created` - For admin dashboards

3. **Enterprise Groups**
   - Similar indexing pattern as teams
   - Composite indexes for common queries

4. **Invitations**
   - `index_invitations_on_expires_at` - For expiration checks
   - `index_invitations_on_invitable_and_accepted` - For polymorphic queries
   - `index_invitations_on_email_and_accepted` - For duplicate checks

5. **Audit Logs**
   - Composite indexes on user_id/target_user_id with created_at
   - `index_audit_logs_on_action_and_created` - For activity reports

### Migration

```ruby
class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # User indexes
    add_index :users, [:status, :last_activity_at], name: 'index_users_on_status_and_activity'
    add_index :users, [:team_id, :status], name: 'index_users_on_team_and_status'
    add_index :users, [:email, :status], name: 'index_users_on_email_and_status'
    
    # Team indexes
    add_index :teams, [:status, :created_at], name: 'index_teams_on_status_and_created'
    add_index :teams, [:slug, :status], name: 'index_teams_on_slug_and_status'
    
    # And more...
  end
end
```

## 4. Query Optimization

### N+1 Query Prevention

The application now includes comprehensive N+1 query prevention:

#### Controller Optimizations

All controllers loading collections now use `includes` to eager load associations:

**`app/controllers/admin/super/users_controller.rb`**
```ruby
def index
  @users = policy_scope(User).includes(:team, :plan, :enterprise_group).order(created_at: :desc)
  @pagy, @users = pagy(@users)
end
```

**`app/controllers/admin/super/teams_controller.rb`**
```ruby
def index
  @teams = policy_scope(Team).includes(:admin, :created_by, :users).order(created_at: :desc)
  @pagy, @teams = pagy(@teams)
end
```

#### Model Scopes

Models now include scopes with eager loading:

**`app/models/team.rb`**
```ruby
scope :with_associations, -> { includes(:admin, :created_by, :users) }
scope :with_counts, -> { left_joins(:users).group(:id).select('teams.*, COUNT(users.id) as users_count') }
```

**`app/models/user.rb`**
```ruby
scope :with_associations, -> { includes(:team, :plan, :enterprise_group) }
scope :with_team_details, -> { includes(team: [:admin, :users]) }
```

### Query Objects

Complex queries are now handled by dedicated query objects:

**`app/queries/users_query.rb`**
```ruby
# Usage in controllers:
@users = UsersQuery.new(policy_scope(User))
  .for_admin_index
  .active
  .exclude_admins
  .newest_first
  .results
```

**`app/queries/teams_query.rb`**
```ruby
# Usage with user counts:
@teams = TeamsQuery.new(policy_scope(Team))
  .for_admin_index  # Includes COUNT of users
  .active
  .newest_first
  .results
```

### Statistics Optimization

Member statistics are now calculated efficiently in controllers:

**`app/controllers/teams/admin/members_controller.rb`**
```ruby
def index
  @members = @team.users.includes(:ahoy_visits).order(created_at: :desc)
  @pagy, @members = pagy(@members)
  
  # Pre-calculate statistics to avoid N+1
  all_members = @team.users
  @admin_count = all_members.where(team_role: 'admin').count
  @member_count = all_members.where(team_role: 'member').count
  @active_count = all_members.where('last_activity_at > ?', 7.days.ago).count
end
```

### Benefits of N+1 Prevention

1. **Reduced Database Load**: Single query with joins instead of N+1 queries
2. **Faster Page Load**: Significant performance improvement on index pages
3. **Better Scalability**: Performance remains consistent as data grows
4. **Lower Memory Usage**: Efficient query execution

## Performance Monitoring

### Key Metrics to Track

1. **Response Times**
   - Average response time per controller action
   - 95th percentile response times
   - Slow query identification

2. **Cache Hit Rates**
   - Fragment cache hit/miss ratio
   - Model cache effectiveness
   - Redis memory usage

3. **Background Jobs**
   - Job queue depth
   - Processing time per job type
   - Failed job rates

### Tools Recommended

1. **APM (Application Performance Monitoring)**
   - New Relic
   - Scout APM
   - AppSignal

2. **Database Monitoring**
   - PgHero (for PostgreSQL)
   - Query analysis tools
   - Slow query logs

3. **Redis Monitoring**
   - Redis memory usage
   - Key expiration patterns
   - Command statistics

## Best Practices

1. **Always measure before optimizing** - Use profiling tools to identify bottlenecks
2. **Cache invalidation** - Ensure caches are properly cleared on updates
3. **Monitor cache size** - Set appropriate expiration times
4. **Index maintenance** - Regularly analyze index usage
5. **Background job reliability** - Implement retry logic and error handling

## Configuration

### Cache Store Configuration

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 1.hour,
  namespace: 'saas_app',
  compress: true,
  compress_threshold: 1.kilobyte
}
```

### Solid Queue Configuration

```ruby
# config/solid_queue.yml
production:
  queues:
    - default
    - low_priority
  workers:
    - queues: [default]
      threads: 5
    - queues: [low_priority]
      threads: 2
```

## Testing Performance Optimizations

### Cache Testing

```ruby
test "should cache team slug lookup" do
  team = teams(:acme)
  
  # First call hits database
  assert_queries(1) do
    Team.find_by_slug!(team.slug)
  end
  
  # Second call uses cache
  assert_queries(0) do
    Team.find_by_slug!(team.slug)
  end
end
```

### Background Job Testing

```ruby
test "should queue activity tracking job" do
  sign_in users(:john)
  
  assert_enqueued_with(job: TrackUserActivityJob) do
    get root_path
  end
end
```

## Conclusion

These performance optimizations significantly improve the application's scalability and responsiveness. Regular monitoring and profiling should guide future optimization efforts.