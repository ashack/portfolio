class Teams::DashboardController < Teams::BaseController
  # Dashboard shows team's own data, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  def index
    @team_members = @team.users.includes(:ahoy_visits).order(created_at: :desc)
    @recent_activities = @team.users.where.not(last_activity_at: nil).order(last_activity_at: :desc).limit(10)
  end
end
