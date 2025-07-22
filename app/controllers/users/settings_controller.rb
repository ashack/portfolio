# Users::SettingsController
#
# PURPOSE: Manages user account settings and notification preferences for direct users
# in the triple-track SaaS system. Provides comprehensive notification management and
# account preference controls with secure email change protection.
#
# SCOPE: Direct users only - part of the triple-track system where:
# - Direct users: Individual registrations with full settings control
# - Invited users: Team members (limited settings access through team interface)
# - Enterprise users: Large organization members (limited settings access)
#
# FUNCTIONALITY:
# - Account settings viewing and modification
# - Comprehensive notification preference management (email, in-app, digest)
# - Security-conscious email change protection
# - JSON-based notification preference storage with proper structure
# - Marketing preference management
# - Basic profile information updates
#
# SECURITY:
# - EmailChangeProtection prevents unauthorized email changes
# - Email changes must go through secure EmailChangeRequest workflow
# - Security alerts are always enabled and cannot be disabled
# - Proper parameter filtering to prevent mass assignment attacks
#
class Users::SettingsController < Users::BaseController
  # Include email change protection to prevent unauthorized account takeover
  # This concern intercepts email change attempts and routes them securely
  include EmailChangeProtection

  # Skip Pundit verification since users only access their own settings
  # Authorization is inherent through current_user scoping
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /users/settings
  # Display user settings interface with current preferences and configurations
  def show
    @user = current_user
    # Shows comprehensive settings including notification preferences,
    # account information, and security settings
  end

  # PATCH/PUT /users/settings
  # Update user settings and notification preferences with structured JSON storage
  def update
    @user = current_user

    if @user.update(settings_params)
      redirect_to users_settings_path, notice: "Settings updated successfully."
    else
      # Re-render settings form with validation errors
      render :show, status: :unprocessable_entity
    end
  end

  private

  # SECURITY: Strict parameter filtering with email change protection
  # Prevents mass assignment attacks and unauthorized account modifications
  def settings_params
    # SECURITY: Email changes must go through the EmailChangeRequest system
    # Never permit direct email updates to prevent unauthorized account takeover
    # EmailChangeProtection concern will intercept any email change attempts
    permitted = params.require(:user).permit(:first_name, :last_name)

    # Handle notification preferences separately to properly structure the JSON
    # This ensures the notification_preferences are stored as properly structured JSON
    if params[:user][:notification_preferences].present?
      permitted[:notification_preferences] = build_notification_preferences
    end

    permitted
  end

  # COMPLEX JSON BUILDER: Structure notification preferences for database storage
  # Builds comprehensive notification preference JSON with security safeguards
  # and proper boolean conversion from form checkbox values
  def build_notification_preferences
    prefs = params[:user][:notification_preferences]

    # Start with existing preferences to preserve any unlisted settings
    existing = current_user.notification_preferences || {}

    # Build the structured preferences with proper boolean conversion
    # Form checkboxes send "1" for checked, need conversion to boolean
    {
      "email" => {
        # User-configurable email notifications
        "status_changes" => prefs.dig(:email, :status_changes) == "1",
        "security_alerts" => true, # SECURITY: Always true - cannot be disabled
        "role_changes" => prefs.dig(:email, :role_changes) == "1",
        "team_members" => prefs.dig(:email, :team_members) == "1",
        "invitations" => prefs.dig(:email, :invitations) == "1",
        "admin_actions" => prefs.dig(:email, :admin_actions) == "1",
        "account_updates" => prefs.dig(:email, :account_updates) == "1"
      },
      "in_app" => {
        # User-configurable in-app notifications
        "status_changes" => prefs.dig(:in_app, :status_changes) == "1",
        "security_alerts" => true, # SECURITY: Always true - cannot be disabled
        "role_changes" => prefs.dig(:in_app, :role_changes) == "1",
        "team_members" => prefs.dig(:in_app, :team_members) == "1",
        "invitations" => prefs.dig(:in_app, :invitations) == "1",
        "admin_actions" => prefs.dig(:in_app, :admin_actions) == "1",
        "account_updates" => prefs.dig(:in_app, :account_updates) == "1"
      },
      "digest" => {
        # Email digest frequency (daily, weekly, monthly, never)
        "frequency" => prefs.dig(:digest, :frequency) || "daily"
      },
      "marketing" => {
        # Marketing communications opt-in (GDPR/compliance friendly)
        "enabled" => prefs.dig(:marketing, :enabled) == "1"
      }
    }
  end
end
