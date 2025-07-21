class Users::ConfirmationsController < Devise::ConfirmationsController
  skip_before_action :authenticate_user!
  skip_before_action :check_user_status
  skip_before_action :track_user_activity_async
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  
  layout "minimal"

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      # Check if the error is due to an expired token
      if resource.errors.details[:confirmation_token].any? { |e| e[:error] == :expired }
        handle_expired_token
      elsif resource.errors.details[:email].any? { |e| e[:error] == :already_confirmed }
        # User is already confirmed
        set_flash_message!(:notice, :already_confirmed)
        redirect_to new_user_session_path
      else
        respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
      end
    end
  end

  # GET /resource/confirmation/new
  def new
    super
  end

  # POST /resource/confirmation
  def create
    super
  end

  # GET /users/confirmation/expired
  def expired
    # This action renders the expired token view
  end

  protected

  # The path used after resending confirmation instructions.
  def after_resending_confirmation_instructions_path_for(resource_name)
    new_user_session_path
  end

  # The path used after confirmation.
  def after_confirmation_path_for(resource_name, resource)
    if signed_in?(resource_name)
      signed_in_root_path(resource)
    else
      new_user_session_path
    end
  end

  private

  def handle_expired_token
    # Try to find user with the confirmation token
    # Devise stores the token in a hashed format, so we need to use the resource from the show action
    if resource && resource.email.present?
      # The resource already has the user with errors from confirm_by_token
      # Generate a new confirmation token and send instructions
      resource.send_confirmation_instructions
      session[:expired_confirmation_email] = resource.email
      redirect_to expired_users_confirmations_path
    else
      # If we can't find the user, redirect to sign in
      set_flash_message!(:alert, :invalid_token)
      redirect_to new_user_session_path
    end
  end
end