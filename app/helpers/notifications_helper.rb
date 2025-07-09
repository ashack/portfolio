module NotificationsHelper
  def notification_icon_bg_class(notification)
    notification_type = notification.notification_type
    
    case notification_type
    when "status_change", "account_update"
      "bg-green-100"
    when "role_change", "admin_action"
      "bg-indigo-100"
    when "security_alert"
      "bg-red-100"
    when "email_change"
      "bg-yellow-100"
    when "team_invitation", "enterprise_invitation", "team_update"
      "bg-blue-100"
    when "system_announcement"
      "bg-purple-100"
    else
      "bg-gray-100"
    end
  end

  def notification_icon_color_class(notification)
    notification_type = notification.notification_type
    
    case notification_type
    when "status_change", "account_update"
      "text-green-600"
    when "role_change", "admin_action"
      "text-indigo-600"
    when "security_alert"
      "text-red-600"
    when "email_change"
      "text-yellow-600"
    when "team_invitation", "enterprise_invitation", "team_update"
      "text-blue-600"
    when "system_announcement"
      "text-purple-600"
    else
      "text-gray-600"
    end
  end

  def notification_priority_badge(notification)
    return unless notification.priority

    case notification.priority
    when "critical"
      content_tag :span, "Critical",
        class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800"
    when "high"
      content_tag :span, "High",
        class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-800"
    when "medium"
      content_tag :span, "Medium",
        class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800"
    else
      nil
    end
  end

  def unread_notifications_count
    @unread_notifications_count ||= current_user.notifications.unread.count
  end

  def has_unread_notifications?
    unread_notifications_count > 0
  end
end
