class Teams::ProfileController < Teams::BaseController
  include EmailChangeProtection
  
  # Skip Pundit verification since profile shows user's own data
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  before_action :set_user

  def show
    # Show team member profile (read-only view)
  end

  def edit
    # Edit team member profile form
  end

  def update
    if @user.update(profile_params)
      # Calculate profile completion after update
      @user.calculate_profile_completion
      redirect_to teams_profile_path(team_slug: @team.slug, id: @user), notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
    # Ensure user can only access their own profile
    redirect_to team_root_path(team_slug: @team.slug), alert: "Access denied." if params[:id] && params[:id].to_i != current_user.id
  end

  def profile_params
    # EmailChangeProtection concern will handle email change attempts
    params.require(:user).permit(
      :first_name, :last_name, :bio, :phone_number, :avatar_url, :avatar,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url,
      notification_preferences: {}
    )
  end
end
