class Admin::Super::DashboardController < Admin::Super::BaseController
  # Dashboard shows statistics, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  
  def index
    # Super admin stats (all data)
    @total_users = User.count
    @total_teams = Team.count
    @active_teams = Team.active.count
    @direct_users = User.direct_users.count
    @team_users = User.team_members.count
    
    # Site admin stats (excluding super admins)
    @active_users = User.active.where.not(system_role: "super_admin").count
    @inactive_users = User.inactive.count
    @locked_users = User.locked.count
    
    # Recent data
    @recent_teams = Team.order(created_at: :desc).limit(5)
    @recent_users = User.where.not(system_role: "super_admin").order(created_at: :desc).limit(10)
    @recent_activities = User.where.not(system_role: "super_admin").order(last_activity_at: :desc).limit(10)
  end
end
