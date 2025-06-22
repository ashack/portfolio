class TrackUserActivityJob < ApplicationJob
  queue_as :low_priority

  # Limit how often we update the database (every 5 minutes)
  ACTIVITY_UPDATE_INTERVAL = 5.minutes

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Check if we need to update based on last activity
    last_activity = user.last_activity_at
    return if last_activity && last_activity > ACTIVITY_UPDATE_INTERVAL.ago

    # Update the activity timestamp
    user.update_column(:last_activity_at, Time.current)
  rescue ActiveRecord::RecordNotFound
    # User was deleted, ignore
  end
end
