class Users::EmailVerificationController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_confirmed
  before_action :ensure_direct_user

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  
  layout "minimal"

  # GET /users/email_verification
  def show
    # Just render the view - all data comes from current_user
  end

  # POST /users/email_verification/resend
  def resend
    service = Users::ResendConfirmationService.new(current_user, current_user, request)
    result = service.call

    if result.success?
      redirect_to users_email_verification_path,
                  notice: "Verification email has been sent to #{current_user.email}. Please check your inbox."
    else
      redirect_to users_email_verification_path,
                  alert: result.error
    end
  end

  private

  def redirect_if_confirmed
    if current_user.confirmed?
      redirect_to redirect_after_sign_in_path
    end
  end

  def ensure_direct_user
    unless current_user.direct?
      redirect_to root_path, alert: "This page is only for direct users."
    end
  end

  def redirect_after_sign_in_path
    if current_user.direct? && !current_user.onboarding_completed? && current_user.plan_id.nil?
      users_onboarding_path
    elsif current_user.direct? && current_user.owns_team? && current_user.team
      team_root_path(team_slug: current_user.team.slug)
    else
      user_dashboard_path
    end
  end
end
