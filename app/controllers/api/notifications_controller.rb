module Api
  class NotificationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_notification, only: [ :mark_as_read ]

    def index
      @notifications = current_user.notifications
                                   .includes(:event)
                                   .order(created_at: :desc)
                                   .limit(10)

      # Apply filters
      case params[:filter]
      when "unread"
        @notifications = @notifications.unread
      when "read"
        @notifications = @notifications.read
      end

      render json: {
        notifications: @notifications.map { |n| notification_json(n) },
        unread_count: current_user.notifications.unread.count,
        has_more: current_user.notifications.count > 10
      }
    end

    def unread_count
      render json: {
        count: current_user.notifications.unread.count,
        has_unread: current_user.notifications.unread.exists?
      }
    end

    def mark_as_read
      @notification.mark_as_read!

      render json: {
        success: true,
        notification: notification_json(@notification),
        unread_count: current_user.notifications.unread.count
      }
    end

    def mark_all_as_read
      current_user.notifications.unread.mark_as_read!

      render json: {
        success: true,
        unread_count: 0
      }
    end

    private

    def set_notification
      @notification = current_user.notifications.find(params[:id])
    end

    def notification_json(notification)
      event = notification.event

      {
        id: notification.id,
        type: event.class.name,
        message: event.message,
        icon: event.icon,
        icon_color: icon_color_for(event),
        url: event.url,
        read: notification.read?,
        created_at: notification.created_at,
        time_ago: time_ago_in_words(notification.created_at),
        params: event.params
      }
    end

    def icon_color_for(event)
      case event.notification_type
      when "status_change", "account_update"
        "text-green-600"
      when "role_change", "admin_action"
        "text-indigo-600"
      when "security_alert"
        "text-red-600"
      when "email_change"
        "text-yellow-600"
      else
        "text-gray-600"
      end
    end
  end
end
