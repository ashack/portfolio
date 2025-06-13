class Users::SettingsController < Users::BaseController
  # Skip Pundit verification since settings shows user's own data
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  def index
    @user = current_user
  end

  def update
    @user = current_user
    
    if @user.update(settings_params)
      redirect_to users_settings_path, notice: "Settings updated successfully."
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:email, :first_name, :last_name)
  end
end