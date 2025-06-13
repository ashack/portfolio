class Admin::Super::AnalyticsController < Admin::Super::BaseController
  # Analytics shows statistics, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  def index
    # User analytics
    @total_users = User.count
    @users_by_status = User.group(:status).count
    @users_by_type = User.group(:user_type).count
    
    # Team analytics
    @total_teams = Team.count
    @teams_by_status = Team.group(:status).count
    
    # Activity analytics
    @active_users_last_30_days = User.where('last_activity_at > ?', 30.days.ago).count
    @new_users_last_30_days = User.where('created_at > ?', 30.days.ago).count
    @new_teams_last_30_days = Team.where('created_at > ?', 30.days.ago).count
    
    # Sign in analytics
    @sign_ins_last_30_days = User.where('last_sign_in_at > ?', 30.days.ago).count
    @average_sign_in_count = User.average(:sign_in_count).to_f.round(1)
    
    # Monthly data (last 12 months) - manual grouping
    @users_by_month = {}
    @teams_by_month = {}
    12.times do |i|
      month = i.months.ago.beginning_of_month
      month_end = month.end_of_month
      @users_by_month[month] = User.where(created_at: month..month_end).count
      @teams_by_month[month] = Team.where(created_at: month..month_end).count
    end
  end
end