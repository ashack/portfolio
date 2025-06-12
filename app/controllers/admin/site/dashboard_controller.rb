class Admin::Site::DashboardController < Admin::Site::BaseController
  def index
    @total_users = User.where.not(system_role: "super_admin").count
    @active_users = User.active.where.not(system_role: "super_admin").count
    @inactive_users = User.inactive.count
    @locked_users = User.locked.count
    @recent_users = User.where.not(system_role: "super_admin").order(created_at: :desc).limit(10)
    @recent_activities = User.where.not(system_role: "super_admin").order(last_activity_at: :desc).limit(10)
  end
end
