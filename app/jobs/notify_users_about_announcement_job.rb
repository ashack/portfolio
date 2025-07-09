# Background job to send notifications to all active users when a new announcement is published
class NotifyUsersAboutAnnouncementJob < ApplicationJob
  queue_as :default

  def perform(announcement)
    # Only send notifications for published, active announcements
    return unless announcement.published? && announcement.active?

    # Send notifications to all active users
    User.active.find_each do |user|
      # Determine priority based on announcement style
      priority = case announcement.style
      when "danger" then "critical"
      when "warning" then "high"
      when "success", "info" then "medium"
      else "medium"
      end

      # Determine announcement type based on content
      announcement_type = case announcement.style
      when "danger", "warning" then "maintenance"
      when "success" then "feature"
      else "general"
      end

      # Send notification using the existing SystemAnnouncementNotifier
      SystemAnnouncementNotifier.deliver(
        user,
        title: announcement.title,
        message: announcement.message,
        priority: priority,
        announcement_type: announcement_type
      )
    end
  end
end

