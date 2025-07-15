module ApplicationHelper
  include Pagy::Frontend

  def edit_profile_path_for(user)
    if user.direct?
      edit_users_profile_path(user)
    elsif user.invited? && user.team
      edit_teams_profile_path(team_slug: user.team.slug, id: user)
    elsif user.enterprise? && user.enterprise_group
      edit_enterprise_profile_path(user.enterprise_group.slug)
    else
      root_path
    end
  end

  def profile_path_for(user)
    if user.direct?
      users_profile_path(user)
    elsif user.invited? && user.team
      teams_profile_path(team_slug: user.team.slug, id: user)
    elsif user.enterprise? && user.enterprise_group
      enterprise_profile_path(user.enterprise_group.slug)
    else
      root_path
    end
  end

  def priority_badge_class(priority)
    case priority.to_s
    when "critical"
      "bg-red-100 text-red-800"
    when "high"
      "bg-orange-100 text-orange-800"
    when "medium"
      "bg-yellow-100 text-yellow-800"
    when "low"
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
