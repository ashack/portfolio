# Teams::ProfileController - Team member profile management
#
# PURPOSE:
# - Manages individual team member profile information within team context
# - Provides profile viewing and editing for team members
# - Implements secure email change protection for team members
# - Calculates and tracks profile completion metrics
#
# ACCESS LEVEL: Team Member (Self-Service)
# - Users can only view and edit their own profile
# - No access to other team members' profiles (admin functionality)
# - Available to both invited users and direct users who own teams
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/profile (show current user's profile)
# - GET /teams/:team_slug/profile/:id (show specific user profile)
# - GET /teams/:team_slug/profile/edit (edit current user's profile)
# - PATCH /teams/:team_slug/profile/:id (update user profile)
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS: Primary users - manage their team member profiles
# - DIRECT USERS (team owners): Can manage profile while maintaining team owner status
# - ENTERPRISE USERS: Cannot access (separate enterprise profile management)
#
# EMAIL CHANGE PROTECTION:
# - Integrates EmailChangeProtection concern for secure email updates
# - Email changes require approval workflow for security
# - Prevents unauthorized email changes that could compromise account security
# - Team context preserved during email change process
#
# PROFILE FEATURES:
# - Personal information (name, bio, contact details)
# - Social media links (LinkedIn, Twitter, GitHub, website)
# - Avatar/photo management
# - Timezone and locale settings
# - Profile visibility controls
# - Notification preferences
# - Profile completion tracking
#
# SECURITY CONSIDERATIONS:
# - Users can only access their own profile (strict self-service)
# - Email changes protected by EmailChangeProtection concern
# - Profile updates validated and sanitized
# - No cross-team profile access (team scope enforced)
# - Sensitive profile changes logged for audit purposes
#
class Teams::ProfileController < Teams::BaseController
  include EmailChangeProtection

  # Skip Pundit verification since profile shows user's own data
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  before_action :set_user

  # PROFILE DISPLAY
  # Shows the team member's profile information in read-only view
  # Includes profile completion status and team context
  def show
    # Show team member profile (read-only view)
    # Profile completion percentage calculated for user engagement
    # Social media links and contact information displayed
    # Team context maintained for navigation and branding
  end

  # PROFILE EDIT FORM
  # Displays the profile editing form with current user information
  # Includes all editable profile fields and validation messages
  def edit
    # Edit team member profile form
    # Pre-populated with current user data
    # Includes validation and error handling
    # Email change protection notices displayed if applicable
  end

  # PROFILE UPDATE
  # Processes profile updates with validation and security checks
  # Recalculates profile completion after successful update
  def update
    if @user.update(profile_params)
      # Calculate profile completion after update for user engagement metrics
      @user.calculate_profile_completion
      redirect_to teams_profile_path(team_slug: @team.slug, id: @user), notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # USER AUTHORIZATION
  # Ensures users can only access their own profile information
  # Prevents unauthorized access to other team members' profiles
  def set_user
    @user = current_user
    # Ensure user can only access their own profile - strict self-service security
    redirect_to team_root_path(team_slug: @team.slug), alert: "Access denied." if params[:id] && params[:id].to_i != current_user.id
  end

  # PROFILE PARAMETER FILTERING
  # Defines allowed profile parameters with security considerations
  # EmailChangeProtection concern handles email changes separately
  def profile_params
    # EmailChangeProtection concern will handle email change attempts
    # This prevents direct email updates and routes them through approval workflow
    params.require(:user).permit(
      :first_name, :last_name, :bio, :phone_number, :avatar_url, :avatar,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url,
      notification_preferences: {}
    )
  end
end
