class Users::DashboardController < Users::BaseController
  def index
    @user = current_user
    @subscription = @user.payment_processor&.subscription
    @recent_activities = @user.ahoy_visits.order(started_at: :desc).limit(5)
  end
end