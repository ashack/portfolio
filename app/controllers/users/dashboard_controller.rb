# Dashboard controller for direct users
# Displays personal dashboard with subscription info and recent activity
# Only accessible to direct users (not team/enterprise users)
class Users::DashboardController < Users::BaseController
  # Skip Pundit checks - dashboard shows user's own data, not managed resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  # GET /dashboard
  # Display personal dashboard for direct users
  # Shows subscription status, recent activities, and account overview
  def index
    # Set up dashboard data
    @user = current_user
    @subscription = nil
    # Load recent activities for dashboard display (limited for performance)
    @recent_activities = @user.ahoy_visits.order(started_at: :desc).limit(5)

    # Safely check for payment processor (Pay gem integration)
    # Only try to access payment processor if the user has one set up
    if @user.respond_to?(:payment_processor) && @user.payment_processor.present?
      @subscription = @user.payment_processor.subscription
    end

    # Use modern view template with sidebar layout
    render "index_modern"
  end
end
