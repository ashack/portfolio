class Users::DashboardController < Users::BaseController
  # Skip policy scoping since dashboard shows user's own data, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  def index
    @user = current_user
    @subscription = nil
    @recent_activities = @user.ahoy_visits.order(started_at: :desc).limit(5)

    # Only try to access payment processor if the user has one set up
    if @user.respond_to?(:payment_processor) && @user.payment_processor.present?
      @subscription = @user.payment_processor.subscription
    end

    # Use modern view template
    render "index_modern"
  end
end
