class Users::ProfileController < Users::BaseController
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
    # Remove email from permitted params to prevent direct email changes
    permitted_params = params.require(:user).permit(
      :first_name, :last_name, :bio, :phone_number, :avatar_url,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url,
      notification_preferences: {}
    )

    # Show warning if user tries to change email
    if params[:user][:email].present? && params[:user][:email] != current_user.email
      flash.now[:alert] = "Email changes must be requested through the email change request system for security reasons."
    end

    permitted_params
  end
end
