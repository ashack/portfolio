# Custom sessions controller for handling user login/logout
# Extends Devise functionality with email verification checks and custom redirects
class Users::SessionsController < Devise::SessionsController
  # Skip authentication checks for login/logout actions (users aren't logged in yet)
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  skip_before_action :check_user_status, only: [ :new, :create ]
  skip_before_action :track_user_activity_async, only: [ :new, :create ]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  
  # Handle CSRF token failures gracefully (e.g., expired sessions)
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_token
  
  # Use minimal layout for cleaner login experience
  layout "minimal", only: [:new]

  # POST /resource/sign_in
  # Override to handle Turbo properly and ensure smooth login experience
  def create
    # Authenticate user using Devise/Warden
    self.resource = warden.authenticate!(auth_options)
    # Set success flash message
    set_flash_message!(:notice, :signed_in)
    # Sign in the user
    sign_in(resource_name, resource)
    yield resource if block_given?

    # Handle both regular HTTP and Turbo requests
    respond_to do |format|
      format.html { redirect_to after_sign_in_path_for(resource) }
      format.turbo_stream { redirect_to after_sign_in_path_for(resource), status: :see_other }
    end
  end

  # DELETE /resource/sign_out
  # Override to handle Turbo properly for logout
  def destroy
    # Sign out the user (either current scope or all scopes based on Devise config)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    # Show success message if successfully signed out
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?

    # Handle both regular HTTP and Turbo requests with proper redirect status
    respond_to do |format|
      format.all { redirect_to after_sign_out_path_for(resource_name), status: :see_other }
      format.turbo_stream { redirect_to after_sign_out_path_for(resource_name), status: :see_other }
    end
  end
  
  protected
  
  # Override to handle post-sign-in redirect for onboarding and email verification
  # This method determines where users go after successful login based on their status
  def after_sign_in_path_for(resource)
    # IMPORTANT: Check if direct user needs email verification
    # This enforces our email verification requirement
    if resource.direct? && !resource.confirmed?
      users_email_verification_path
    # Check if user needs onboarding (direct users without a plan)
    elsif resource.direct? && !resource.onboarding_completed? && resource.plan_id.nil?
      users_onboarding_path
    else
      # Use stored location (if user was trying to access a specific page)
      # or fall back to default Devise behavior
      stored_location_for(resource) || super
    end
  end
  
  private
  
  # Handle expired CSRF tokens gracefully
  # This can happen when login page is left open for a long time
  def handle_invalid_token
    # Clear the session to start fresh
    reset_session
    # Show helpful error message
    flash[:alert] = "Your session has expired. Please try again."
    # Redirect back to login page
    redirect_to new_user_session_path
  end
end
