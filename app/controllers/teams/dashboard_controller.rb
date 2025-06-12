class Teams::DashboardController < Teams::BaseController
  def index
    @team_members = @team.users.includes(:invitations).order(created_at: :desc)
    @recent_activities = @team.users.joins(:ahoy_visits).order('ahoy_visits.started_at DESC').limit(10)
  end
end