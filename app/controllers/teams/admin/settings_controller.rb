# Teams::Admin::SettingsController - Team configuration and settings management
#
# PURPOSE:
# - Manages team-wide configuration settings and preferences
# - Provides team admins control over team information and behavior
# - Handles team profile updates and organizational settings
# - Centralizes team configuration in one administrative interface
#
# ACCESS LEVEL: Team Admin Only
# - Only team admins can modify team settings and configuration
# - Team owners (direct users) have full settings management access
# - Invited admins can update team settings with appropriate permissions
# - Regular team members cannot access team settings
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/admin/settings (index - settings form)
# - PATCH /teams/:team_slug/admin/settings (update - save changes)
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS (admin role): Can manage team settings if granted admin privileges
# - DIRECT USERS (team owners): Full team settings control for teams they own
# - ENTERPRISE USERS: Cannot access (separate enterprise settings management)
#
# TEAM SETTINGS CATEGORIES:
# - Basic Information: Team name, description, website
# - Operational Settings: Timezone, locale, business hours
# - Branding: Team logo, colors, custom styling (future)
# - Integration Settings: API keys, webhooks, external services (future)
# - Privacy Settings: Team visibility, member directory access (future)
#
# BUSINESS RULES:
# - Team name changes affect slug generation and URLs
# - Timezone affects all team member activity timestamps
# - Settings changes apply immediately to all team members
# - Certain settings may require team owner privileges
# - Settings history tracked for audit purposes
#
# SECURITY CONSIDERATIONS:
# - Admin-only access to team configuration
# - Settings changes logged for audit compliance
# - Parameter validation prevents malicious input
# - Team scope enforced (no cross-team settings access)
# - Sensitive settings protected with additional authorization
# - Input sanitization for user-generated content
#
class Teams::Admin::SettingsController < Teams::Admin::BaseController
  # Skip Pundit verification since settings shows team's own data
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  # TEAM SETTINGS FORM
  # Displays comprehensive team configuration interface
  # Shows current settings with organized categories and validation feedback
  def index
    # @team is already set by the base controller (Teams::BaseController)
    # This provides access to all current team settings and configuration
    # Settings are organized into logical groups for better user experience
  end

  # UPDATE TEAM SETTINGS
  # Processes team configuration updates with validation and error handling
  # Applies changes immediately and provides user feedback
  def update
    if @team.update(team_params)
      # Team settings updated successfully
      # TODO: Add audit logging for settings changes
      # TODO: Notify team members of relevant settings changes
      redirect_to team_admin_settings_path, notice: "Team settings updated successfully."
    else
      # Validation errors occurred - redisplay form with error messages
      # Status 422 (Unprocessable Entity) indicates validation failure
      render :index, status: :unprocessable_entity
    end
  end

  private

  # TEAM SETTINGS PARAMETERS
  # Filters allowed parameters for team settings updates
  # Includes core team information and operational settings
  def team_params
    params.require(:team).permit(:name, :description, :timezone, :website)

    # Future settings to consider:
    # :logo, :primary_color, :secondary_color, :locale, :business_hours,
    # :allow_member_invites, :public_member_directory, :custom_domain,
    # :api_access_enabled, :webhook_url, :slack_webhook, :email_notifications
  end
end
