class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  
  def index
    if user_signed_in?
      redirect_to redirect_path_for_user
    end
  end
  
  private
  
  def redirect_path_for_user
    if current_user.super_admin?
      admin_super_root_path
    elsif current_user.site_admin?
      admin_site_root_path
    elsif current_user.direct?
      user_dashboard_path
    elsif current_user.invited? && current_user.team
      team_root_path(team_slug: current_user.team.slug)
    else
      root_path
    end
  end
end