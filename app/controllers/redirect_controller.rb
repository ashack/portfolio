class RedirectController < ApplicationController
  def after_sign_in
    if current_user.super_admin?
      redirect_to admin_super_root_path
    elsif current_user.site_admin?
      redirect_to admin_site_root_path
    elsif current_user.direct?
      redirect_to user_dashboard_path
    elsif current_user.invited? && current_user.team
      redirect_to team_root_path(team_slug: current_user.team.slug)
    else
      redirect_to root_path
    end
  end
end
