# Custom confirmations controller extending Devise functionality
# Handles email confirmation for direct users with enhanced error handling
# Features automatic token regeneration for expired confirmations
class Users::ConfirmationsController < Devise::ConfirmationsController
  # Skip authentication checks - users confirming email aren't logged in yet
  skip_before_action :authenticate_user!
  skip_before_action :check_user_status
  skip_before_action :track_user_activity_async
  # Skip Pundit authorization for public confirmation actions
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  
  # Use minimal layout for cleaner confirmation experience
  layout "minimal"

  # GET /resource/confirmation?confirmation_token=abcdef
  # Handles email confirmation when user clicks the link in their email
  # Enhanced with automatic token regeneration for expired confirmations
  def show
    # Attempt to confirm user by token
    # This validates the token and marks the user as confirmed
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      # Confirmation successful - show success message
      set_flash_message!(:notice, :confirmed)
      # Redirect to appropriate path (login page by default)
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      # Handle various error scenarios
      # Check if the error is due to an expired token
      if resource.errors.details[:confirmation_token].any? { |e| e[:error] == :expired }
        # Token expired - automatically send new confirmation email
        handle_expired_token
      elsif resource.errors.details[:email].any? { |e| e[:error] == :already_confirmed }
        # User already confirmed - redirect to login with message
        set_flash_message!(:notice, :already_confirmed)
        redirect_to new_user_session_path
      else
        # Other errors (invalid token, etc.) - show error form
        respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
      end
    end
  end

  # GET /resource/confirmation/new
  # Display form to request new confirmation instructions
  # Users can enter their email to receive a new confirmation link
  def new
    super
  end

  # POST /resource/confirmation
  # Handle form submission to resend confirmation instructions
  # Sends new confirmation email if valid email provided
  def create
    super
  end

  # GET /users/confirmation/expired
  # Custom action to show expired token message
  # Displayed after automatic regeneration of confirmation token
  def expired
    # This action renders the expired token view
    # View shows message that new confirmation email was sent
  end

  protected

  # The path used after resending confirmation instructions
  # Redirects to login page so user can check email and try again
  def after_resending_confirmation_instructions_path_for(resource_name)
    new_user_session_path
  end

  # The path used after successful confirmation
  # Routes user to appropriate location based on authentication status
  def after_confirmation_path_for(resource_name, resource)
    if signed_in?(resource_name)
      # If somehow already signed in, go to their dashboard
      signed_in_root_path(resource)
    else
      # Normal case - redirect to login page to sign in
      new_user_session_path
    end
  end

  private

  # Handle expired confirmation token scenario
  # Automatically sends new confirmation email for better UX
  # This prevents users from getting stuck with expired links
  def handle_expired_token
    # Try to find user with the confirmation token
    # Devise stores the token in a hashed format, so we need to use the resource from the show action
    if resource && resource.email.present?
      # The resource already has the user with errors from confirm_by_token
      # Generate a new confirmation token and send instructions
      resource.send_confirmation_instructions
      # Store email in session for expired page display
      session[:expired_confirmation_email] = resource.email
      # Redirect to custom expired page with helpful message
      redirect_to expired_users_confirmations_path
    else
      # If we can't find the user, redirect to sign in
      # This handles corrupted or invalid tokens
      set_flash_message!(:alert, :invalid_token)
      redirect_to new_user_session_path
    end
  end
end