module OnboardingCheck
  extend ActiveSupport::Concern

  included do
    before_action :check_onboarding_status
  end

  private

  def check_onboarding_status
    return unless user_signed_in?
    return unless current_user.direct?
    return if current_user.onboarding_completed?

    # Skip onboarding check for unconfirmed users - they need to verify email first
    return unless current_user.confirmed?

    # Skip onboarding check for certain controllers/actions
    return if skip_onboarding_check?

    # If user doesn't have a plan and hasn't completed onboarding, redirect
    if current_user.plan_id.nil?
      redirect_to users_onboarding_path unless request.path.start_with?("/users/onboarding")
    end
  end

  def skip_onboarding_check?
    # Skip for devise controllers
    devise_controller? ||
    # Skip for onboarding controller itself
    controller_name == "onboarding" ||
    # Skip for email verification controller
    controller_name == "email_verification" ||
    # Skip for specific paths that should be accessible
    request.path.start_with?("/users/onboarding") ||
    request.path.start_with?("/users/email_verification") ||
    request.path == "/users/sign_out" ||
    # Skip for assets and other non-app paths
    request.path.start_with?("/assets") ||
    request.path.start_with?("/rails")
  end
end
