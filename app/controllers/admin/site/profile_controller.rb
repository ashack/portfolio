# Site Admin Profile Controller
#
# PURPOSE:
# Allows site administrators to manage their own profile information and preferences.
# This is personal profile management for the site admin user, not customer management.
#
# ACCESS RESTRICTIONS:
# - Site admins can only manage their OWN profile
# - No access to other users' profiles through this controller
# - Inherits from Admin::Site::BaseController which enforces site_admin role
#
# BUSINESS RULES:
# - Site admins maintain their own professional profile for support interactions
# - Notification preferences are critical for support workflow
# - Security alerts cannot be disabled (forced to true)
# - Profile completion tracking for admin onboarding
#
# SECURITY CONSIDERATIONS:
# - Skips Pundit verification as users manage their own data
# - Current user context enforced through set_user method
# - No sensitive customer data in admin profiles
class Admin::Site::ProfileController < Admin::Site::BaseController
  # Skip Pundit verification since profile shows user's own data
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  before_action :set_user

  # Display site admin's own profile in read-only view
  #
  # PROFILE DATA SHOWN:
  # - Personal information (name, bio, contact details)
  # - Professional links (LinkedIn, GitHub, etc.)
  # - Profile completion percentage
  # - Current notification preferences
  #
  # USE CASES:
  # - Admin reviews their current profile settings
  # - Check notification preferences for support workflow
  # - Verify profile completeness for professional interactions
  def show
    # Show site admin profile (read-only view)
  end

  # Display profile editing form for site admin
  #
  # EDITABLE FIELDS:
  # - Basic information: name, bio, phone, timezone
  # - Professional URLs: LinkedIn, Twitter, GitHub, website
  # - Notification preferences for support workflow
  # - Profile visibility settings
  #
  # BUSINESS REQUIREMENTS:
  # - Complete profiles improve customer support interactions
  # - Proper timezone setting ensures accurate support scheduling
  def edit
    # Edit site admin profile form
  end

  # Process profile update with notification preferences handling
  #
  # SPECIAL HANDLING:
  # - Notification preferences require JSON structure conversion
  # - Profile completion percentage recalculated after update
  # - Security alerts forced to true (cannot be disabled)
  #
  # NOTIFICATION PREFERENCE CATEGORIES:
  # - Email notifications for various admin actions
  # - In-app notifications for real-time updates
  # - Digest frequency for summary emails
  # - Marketing preferences (optional)
  #
  # BUSINESS LOGIC:
  # - Site admins must receive security and role change notifications
  # - Profile completion affects admin onboarding experience
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

  # Set user to current user for profile management
  # 
  # SECURITY: Ensures site admin can only manage their own profile
  # CONTEXT: Always uses current_user to prevent profile hijacking
  def set_user
    @user = current_user
  end

  # Strong parameters for profile updates
  #
  # PERMITTED FIELDS:
  # - Personal: first_name, last_name, bio, phone_number
  # - Avatar: avatar_url, avatar file upload
  # - Localization: timezone, locale
  # - Professional: LinkedIn, Twitter, GitHub, website URLs
  # - Privacy: profile_visibility setting
  #
  # SECURITY: Only allows safe profile fields, no system roles or permissions
  def profile_params
    params.require(:user).permit(
      :first_name, :last_name, :bio, :phone_number, :avatar_url, :avatar,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url
    )
  end

  # Build structured notification preferences JSON from form parameters
  #
  # STRUCTURE:
  # - email: Email notification preferences for various events
  # - in_app: In-application notification preferences
  # - digest: Frequency settings for summary emails
  # - marketing: Optional marketing communication preferences
  #
  # SECURITY ENFORCEMENT:
  # - security_alerts always forced to true (cannot be disabled)
  # - Critical for site admin security awareness
  #
  # BUSINESS LOGIC:
  # - Site admins need notifications for support workflow
  # - Form checkboxes convert to boolean values
  # - Default digest frequency is "daily" if not specified
  #
  # NOTIFICATION CATEGORIES:
  # - status_changes: User account status modifications
  # - security_alerts: Security-related system events (MANDATORY)
  # - role_changes: System role modifications
  # - team_members: Team membership changes
  # - invitations: New invitation activities
  # - admin_actions: Administrative actions performed
  # - account_updates: User account modifications
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
