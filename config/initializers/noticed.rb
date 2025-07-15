# Configure Noticed gem
Rails.application.config.to_prepare do
  # Include our extensions in Noticed::Notification base class
  require "noticed"
  Noticed::Notification.include NoticedNotificationExtensions
end
