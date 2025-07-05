class Users::SettingsController < Users::BaseController
  include EmailChangeProtection

  # Skip Pundit verification since settings shows user's own data
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # Use admin layout for admin users
  layout :determine_layout

  def show
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(settings_params)
      redirect_to users_settings_path, notice: "Settings updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    # SECURITY: Email changes must go through the EmailChangeRequest system
    # Never permit direct email updates to prevent unauthorized account takeover
    params.require(:user).permit(:first_name, :last_name)
  end

  def determine_layout
    if current_user&.super_admin? || current_user&.site_admin?
      "admin"
    else
      "user"
    end
  end
end
