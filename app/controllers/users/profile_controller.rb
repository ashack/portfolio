class Users::ProfileController < Users::BaseController
  include EmailChangeProtection

  # Skip Pundit verification since profile shows user's own data
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  before_action :set_user

  def show
    # Show user profile (read-only view)
  end

  def edit
    # Edit user profile form
  end

  def update
    if @user.update(profile_params)
      # Calculate profile completion after update
      @user.calculate_profile_completion
      redirect_to users_profile_path(@user), notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
    # Ensure user can only access their own profile
    redirect_to root_path, alert: "Access denied." if params[:id] && params[:id].to_i != current_user.id
  end

  def profile_params
    # EmailChangeProtection concern will handle email change attempts
    permitted_attributes = [
      :first_name, :last_name, :bio, :phone_number, :avatar_url, :avatar,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url,
      notification_preferences: {}
    ]

    # Allow super admins to change their email directly
    permitted_attributes << :email if current_user&.super_admin?

    params.require(:user).permit(permitted_attributes)
  end
end
