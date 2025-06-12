class Admin::Super::DashboardController < Admin::Super::BaseController
  def index
    @total_users = User.count
    @total_teams = Team.count
    @active_teams = Team.active.count
    @direct_users = User.direct_users.count
    @team_users = User.team_members.count
    @recent_teams = Team.order(created_at: :desc).limit(5)
    @recent_users = User.order(created_at: :desc).limit(10)
  end
end
