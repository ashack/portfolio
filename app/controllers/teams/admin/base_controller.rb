class Teams::Admin::BaseController < Teams::BaseController
  before_action :require_team_admin!

  private

  def require_team_admin!
    unless current_user.team_admin?
      flash[:alert] = "You must be a team admin to access this area."
      redirect_to team_root_path(team_slug: @team.slug)
    end
  end
end
