# Controller for handling email verification for direct users
# Shows verification pending page and allows resending confirmation emails
# Only accessible to logged-in direct users who haven't confirmed their email
class Users::EmailVerificationController < ApplicationController
  # Ensure user is logged in to access these pages
  before_action :authenticate_user!
  # Redirect to appropriate dashboard if already confirmed
  before_action :redirect_if_confirmed
  # Only direct users need email verification (invited/enterprise skip it)
  before_action :ensure_direct_user

  # Skip Pundit checks - these are personal user actions
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  
  # Use minimal layout for focused verification experience
  layout "minimal"

  # GET /users/email_verification
  # Display email verification pending page
  # Shows message to check email and button to resend
  def show
    # Just render the view - all data comes from current_user
    # View displays current_user.email and resend button
  end

  # POST /users/email_verification/resend
  # Resend confirmation email to current user
  # Uses service object to handle rate limiting and email sending
  def resend
    # Initialize service with current_user as both actor and target
    # Request object used for rate limiting by IP
    service = Users::ResendConfirmationService.new(current_user, current_user, request)
    result = service.call

    if result.success?
      # Success - show confirmation message
      redirect_to users_email_verification_path,
                  notice: "Verification email has been sent to #{current_user.email}. Please check your inbox."
    else
      # Failed - show error (usually rate limit exceeded)
      redirect_to users_email_verification_path,
                  alert: result.error
    end
  end

  private

  # Redirect already confirmed users to appropriate dashboard
  # Prevents confirmed users from accessing verification page
  def redirect_if_confirmed
    if current_user.confirmed?
      redirect_to redirect_after_sign_in_path
    end
  end

  # Ensure only direct users can access email verification
  # Invited and enterprise users don't need email confirmation
  def ensure_direct_user
    unless current_user.direct?
      redirect_to root_path, alert: "This page is only for direct users."
    end
  end

  # Determine where to redirect confirmed users
  # Same logic as sessions controller for consistency
  def redirect_after_sign_in_path
    if current_user.direct? && !current_user.onboarding_completed? && current_user.plan_id.nil?
      # Direct users without plan go to onboarding
      users_onboarding_path
    elsif current_user.direct? && current_user.owns_team? && current_user.team
      # Direct users who own teams go to team dashboard
      team_root_path(team_slug: current_user.team.slug)
    else
      # All other direct users go to individual dashboard
      user_dashboard_path
    end
  end
end
