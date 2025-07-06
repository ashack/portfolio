# Notifier for team member changes
class TeamMemberNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "TeamMailer"
    config.method = :member_change_notification
    config.params = -> { params }
    config.if = -> { notification_enabled?("email", "team_updates") }
  end

  notification_methods do
    def message
      case params[:action]
      when "added"
        "#{params[:member].full_name} was added to #{params[:team].name}"
      when "removed"
        "#{params[:member].full_name} was removed from #{params[:team].name}"
      when "role_changed"
        "#{params[:member].full_name}'s role was changed in #{params[:team].name}"
      else
        "Team member update in #{params[:team].name}"
      end
    end

    def icon
      case params[:action]
      when "added"
        "user-plus"
      when "removed"
        "user-minus"
      else
        "users"
      end
    end

    def notification_type
      "team_update"
    end

    def url
      team = params[:team]
      Rails.application.routes.url_helpers.team_admin_members_path(team_slug: team.slug)
    end
  end
end