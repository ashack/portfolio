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
    permitted_params = profile_params

    # Handle notification preferences separately to properly structure the JSON
    if params[:user][:notification_preferences].present?
      permitted_params[:notification_preferences] = build_notification_preferences
    end

    if @user.update(permitted_params)
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
      :linkedin_url, :twitter_url, :github_url, :website_url
    )
  end

  def build_notification_preferences
    prefs = params[:user][:notification_preferences]

    # Build the structured preferences
    {
      "email" => {
        "status_changes" => prefs.dig(:email, :status_changes) == "1",
        "security_alerts" => true, # Always true - cannot be disabled
        "role_changes" => prefs.dig(:email, :role_changes) == "1",
        "team_members" => prefs.dig(:email, :team_members) == "1",
        "invitations" => prefs.dig(:email, :invitations) == "1",
        "admin_actions" => prefs.dig(:email, :admin_actions) == "1",
        "account_updates" => prefs.dig(:email, :account_updates) == "1"
      },
      "in_app" => {
        "status_changes" => prefs.dig(:in_app, :status_changes) == "1",
        "security_alerts" => true, # Always true - cannot be disabled
        "role_changes" => prefs.dig(:in_app, :role_changes) == "1",
        "team_members" => prefs.dig(:in_app, :team_members) == "1",
        "invitations" => prefs.dig(:in_app, :invitations) == "1",
        "admin_actions" => prefs.dig(:in_app, :admin_actions) == "1",
        "account_updates" => prefs.dig(:in_app, :account_updates) == "1"
      },
      "digest" => {
        "frequency" => prefs.dig(:digest, :frequency) || "daily"
      },
      "marketing" => {
        "enabled" => prefs.dig(:marketing, :enabled) == "1"
      }
    }
  end
end
