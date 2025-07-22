# Custom passwords controller that extends Devise functionality
# Handles password reset flow with additional security checks
class Users::PasswordsController < Devise::PasswordsController
  # Skip authentication and authorization checks since users resetting passwords aren't logged in
  skip_before_action :authenticate_user!
  skip_before_action :check_user_status
  skip_before_action :track_user_activity_async
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # Use minimal layout for cleaner password reset experience
  layout "minimal"

  # POST /resource/password
  # Handles password reset request form submission
  # Override to handle flash messages properly and check confirmation
  def create
    # Call our custom send_reset_password_instructions method that checks confirmation
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      # Redirect to login page with success message
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      # Check if the error is about unconfirmed email
      if resource.errors.added?(:email, :not_confirmed)
        # Show helpful message directing user to confirm email first
        flash[:alert] = "You must confirm your email address before you can reset your password. Please check your email for confirmation instructions."
      end
      # Re-render the form with errors
      respond_with(resource)
    end
  end

  # PUT /resource/password
  # Handles the actual password update after user clicks reset link
  # Override to sign in the user after password reset and add security checks
  def update
    super do |resource|
      if resource.errors.empty?
        # Additional security check: ensure user is confirmed
        # This is a belt-and-suspenders approach - if our create action works correctly,
        # unconfirmed users should never reach this point, but we check anyway
        if !resource.confirmed?
          resource.errors.add(:email, :not_confirmed)
          flash[:alert] = "You must confirm your email address before you can reset your password."
          redirect_to new_user_session_path and return
        end

        # Sign in the user automatically after password reset
        # This is safe because they've already proven email ownership by clicking the reset link
        sign_in(resource_name, resource)

        # Set a success message
        flash[:notice] = "Your password has been changed successfully. You are now signed in."
      end
    end
  end

  protected

  # The path used after sending reset password instructions
  # Redirects to login page so user can check their email
  def after_sending_reset_password_instructions_path_for(resource_name)
    new_session_path(resource_name) if is_navigational_format?
  end

  # The path used after successfully resetting the password
  # Routes users to their appropriate dashboard based on user type
  def after_resetting_password_path_for(resource)
    # Direct users who haven't completed onboarding go to onboarding flow
    if resource.direct? && !resource.onboarding_completed? && resource.plan_id.nil?
      users_onboarding_path
    # Direct users with completed onboarding go to user dashboard
    elsif resource.direct?
      user_dashboard_path
    # Team members go to their team's dashboard
    elsif resource.invited? && resource.team
      team_root_path(team_slug: resource.team.slug)
    # Enterprise users go to their enterprise dashboard
    elsif resource.enterprise? && resource.enterprise_group
      enterprise_dashboard_path(enterprise_group_slug: resource.enterprise_group.slug)
    else
      # Fallback to root path
      root_path
    end
  end
end
