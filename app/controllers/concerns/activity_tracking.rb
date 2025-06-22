module ActivityTracking
  extend ActiveSupport::Concern

  included do
    before_action :track_user_activity_async
  end

  private

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
