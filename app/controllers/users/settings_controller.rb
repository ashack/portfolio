class Users::SettingsController < Users::BaseController
  include EmailChangeProtection

  # Skip Pundit verification since settings shows user's own data
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

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
    permitted = params.require(:user).permit(:first_name, :last_name)

    # Handle notification preferences separately to properly structure the JSON
    if params[:user][:notification_preferences].present?
      permitted[:notification_preferences] = build_notification_preferences
    end

    permitted
  end

  def build_notification_preferences
    prefs = params[:user][:notification_preferences]

    # Start with existing preferences or default structure
    existing = current_user.notification_preferences || {}

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
