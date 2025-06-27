class Admin::Site::ProfileController < Admin::Site::BaseController
  # Skip Pundit verification since profile shows user's own data
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  before_action :set_user

  def show
    # Show site admin profile (read-only view)
  end

  def edit
    # Edit site admin profile form
  end

  def update
    if @user.update(profile_params)
      # Calculate profile completion after update
      @user.calculate_profile_completion
      redirect_to admin_site_profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(
      :first_name, :last_name, :bio, :phone_number, :avatar_url, :avatar,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url,
      notification_preferences: {}
    )
  end
end
