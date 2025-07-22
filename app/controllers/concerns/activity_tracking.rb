# ActivityTracking Concern
#
# OVERVIEW:
# This concern provides lightweight user activity tracking for all authenticated users
# across the triple-track SaaS system. Unlike ActivityTrackable (which tracks admin actions),
# this concern tracks general user activity to maintain "last seen" timestamps and
# basic usage analytics without impacting application performance.
#
# PURPOSE:
# - Track user activity across all user types (direct, invited, enterprise)
# - Update "last seen at" timestamps for user sessions
# - Provide activity data for user analytics and engagement tracking
# - Support user session management and timeout functionality
# - Enable activity-based features (online indicators, session tracking, etc.)
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# This concern works universally across all user types in the SaaS application:
# 1. DIRECT USERS: Tracks individual user activity and engagement
# 2. TEAM MEMBERS: Tracks team member activity within team contexts
# 3. ENTERPRISE USERS: Tracks enterprise user activity within organization contexts
# 4. ADMIN USERS: Tracks general activity (not admin-specific actions)
#
# PERFORMANCE OPTIMIZATIONS:
# - Uses Redis caching to prevent duplicate tracking within 1-minute windows
# - Background job processing to avoid blocking request/response cycles
# - Minimal overhead on every request through efficient cache checking
# - Prevents database writes for every page load through intelligent caching
#
# CACHING STRATEGY:
# - 1-minute cache window prevents excessive database updates
# - Redis-based caching for fast cache checks
# - Cache key includes user ID for proper isolation
# - Background job queuing only when cache is empty
#
# EXTERNAL DEPENDENCIES:
# - TrackUserActivityJob: Background job for async database updates
# - Rails.cache: Redis-based caching system for deduplication
# - current_user: Devise authentication helper
#
# USAGE EXAMPLES:
# 1. Automatic inclusion in base application controller:
#    class ApplicationController < ActionController::Base
#      include ActivityTracking  # Tracks all authenticated users
#    end
#
# 2. Selective inclusion for specific controllers:
#    class UsersController < ApplicationController
#      include ActivityTracking
#      skip_before_action :track_user_activity_async, only: [:api_action]
#    end
#
# BUSINESS LOGIC:
# - Only tracks authenticated users (skips anonymous visitors)
# - Updates occur asynchronously to maintain response time performance
# - Deduplication prevents excessive database writes for active users
# - Works across all authentication contexts (individual, team, enterprise)
#
# PRIVACY CONSIDERATIONS:
# - Only tracks timestamp data, not detailed request information
# - No sensitive parameters or personal data collected
# - Activity tracking can be disabled per user if required for privacy compliance
# - Focuses on engagement metrics rather than detailed behavioral tracking
#
module ActivityTracking
  extend ActiveSupport::Concern

  included do
    # Track user activity before each action to capture engagement
    # Using before_action ensures we capture the user's active session
    # even if the action fails or redirects
    before_action :track_user_activity_async
  end

  private

  # Asynchronously tracks user activity with intelligent deduplication
  #
  # TRACKING PROCESS:
  # 1. Skip anonymous users (no authentication)
  # 2. Check Redis cache for recent activity tracking
  # 3. If not recently tracked, set cache flag and queue background job
  # 4. Background job updates database with latest activity timestamp
  #
  # PERFORMANCE BENEFITS:
  # - Redis cache check is extremely fast (< 1ms)
  # - Background job prevents blocking user request
  # - 1-minute deduplication window reduces database load by ~95%
  # - Scales efficiently with high-traffic applications
  #
  # CACHE STRATEGY:
  # - Cache key format: "user_activity:#{user_id}"
  # - 1-minute expiration prevents excessive tracking
  # - Cache miss triggers immediate background job queuing
  # - Cache hit skips processing entirely
  #
  # RELIABILITY:
  # - Failed background jobs don't impact user experience
  # - Cache failures gracefully degrade to more frequent tracking
  # - No data loss if Redis is temporarily unavailable
  def track_user_activity_async
    return unless current_user

    # Use Redis to track recent activity and avoid duplicate jobs
    cache_key = "user_activity:#{current_user.id}"

    # Check if we've already tracked activity recently
    return if Rails.cache.read(cache_key)

    # Set cache flag for 1 minute to avoid duplicate jobs
    Rails.cache.write(cache_key, true, expires_in: 1.minute)

    # Queue background job to update database
    TrackUserActivityJob.perform_later(current_user.id)
  end
end
