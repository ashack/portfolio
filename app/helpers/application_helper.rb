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
end
