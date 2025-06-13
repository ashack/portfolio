class Teams::DashboardController < Teams::BaseController
  # Dashboard shows team's own data, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  def index
    @team_members = @team.users.order(created_at: :desc)
    @recent_activities = @team.users.joins(:ahoy_visits).order("ahoy_visits.started_at DESC").limit(10)
  end
end
