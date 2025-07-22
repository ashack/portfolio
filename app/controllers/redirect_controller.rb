# Utility controller for handling redirects after authentication
# Provides centralized logic for routing users to appropriate dashboards
class RedirectController < ApplicationController
  # Skip authorization - this is a utility controller for redirects
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  
  # POST /redirect/after_sign_in
  # Central redirect handler for post-authentication routing
  # Implements the triple-track user system routing logic
  def after_sign_in
    if current_user.super_admin?
      # Platform administrators go to super admin dashboard
      redirect_to admin_super_root_path
    elsif current_user.site_admin?
      # Support staff go to site admin dashboard
      redirect_to admin_site_root_path
    elsif current_user.direct? && current_user.owns_team? && current_user.team
      # Direct users who own a team go to their team dashboard
      redirect_to team_root_path(team_slug: current_user.team.slug)
    elsif current_user.direct?
      # Individual direct users go to personal dashboard
      redirect_to user_dashboard_path
    elsif current_user.invited? && current_user.team
      # Team members go to their team's dashboard
      redirect_to team_root_path(team_slug: current_user.team.slug)
    else
      # Fallback to homepage (shouldn't normally happen)
      redirect_to root_path
    end
  end
end
