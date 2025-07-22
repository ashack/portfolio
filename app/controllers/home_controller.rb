# Home page controller - serves as the landing page for the application
# Handles public homepage and redirects logged-in users to appropriate dashboards
class HomeController < ApplicationController
  # Allow public access to homepage without authentication
  skip_before_action :authenticate_user!
  # Skip authorization checks - this is a public page
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /
  # Show homepage for anonymous users or redirect logged-in users
  def index
    if user_signed_in?
      # Redirect authenticated users to their appropriate dashboard
      redirect_to redirect_path_for_user
    end
    # If not signed in, render the homepage view
  end

  private

  # Determine appropriate redirect path based on user type and role
  # Part of the triple-track user system routing logic
  def redirect_path_for_user
    if current_user.super_admin?
      # Platform administrators go to super admin dashboard
      admin_super_root_path
    elsif current_user.site_admin?
      # Support staff go to site admin dashboard
      admin_site_root_path
    elsif current_user.direct?
      # Individual users go to personal dashboard
      user_dashboard_path
    elsif current_user.invited? && current_user.team
      # Team members go to their team's dashboard
      team_root_path(team_slug: current_user.team.slug)
    else
      # Fallback to homepage (shouldn't normally happen)
      root_path
    end
  end
end
