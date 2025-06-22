class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  skip_before_action :check_user_status, only: [ :new, :create ]
  skip_before_action :track_user_activity_async, only: [ :new, :create ]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # Override to handle Turbo properly
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?

    respond_to do |format|
      format.html { redirect_to after_sign_in_path_for(resource) }
      format.turbo_stream { redirect_to after_sign_in_path_for(resource), status: :see_other }
    end
  end

  # Override to handle Turbo properly
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?

    respond_to do |format|
      format.all { redirect_to after_sign_out_path_for(resource_name), status: :see_other }
      format.turbo_stream { redirect_to after_sign_out_path_for(resource_name), status: :see_other }
    end
  end
end
