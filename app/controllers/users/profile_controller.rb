# Users::ProfileController
#
# PURPOSE: Manages user profile information and personal data for direct users in the
# triple-track SaaS system. Handles profile viewing, editing, and completion tracking
# with secure email change protection.
#
# SCOPE: Direct users only - part of the triple-track system where:
# - Direct users: Individual registrations with personal billing
# - Invited users: Team members (have limited profile access)
# - Enterprise users: Large organization members (have limited profile access)
#
# FUNCTIONALITY:
# - Profile viewing (read-only display of user information)
# - Profile editing with comprehensive field support
# - Profile completion calculation and tracking
# - Secure email change protection via EmailChangeProtection concern
# - Social media links and professional information management
# - Notification preferences management
# - Avatar/image upload support
#
# SECURITY:
# - EmailChangeProtection prevents unauthorized email changes
# - Only allows users to access their own profile
# - Super admin email change bypass for administrative purposes
# - Skips Pundit verification since users only access their own data
#
class Users::ProfileController < Users::BaseController
  # Include email change protection to prevent unauthorized account takeover
  # This concern intercepts email change attempts and routes them through
  # the secure EmailChangeRequest workflow
  include EmailChangeProtection

  # Skip Pundit verification since users can only access their own profile
  # Authorization is handled by the set_user method which ensures profile ownership
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  # Load and authorize the user profile before any actions
  before_action :set_user

  # GET /users/profile
  # Display the user's profile in read-only format
  # Shows all profile information including completion percentage
  def show
    # Show user profile (read-only view)
    # Profile completion is automatically calculated and displayed
    # @user is set by before_action and contains all profile data
  end

  # GET /users/profile/edit
  # Display the profile editing form with all editable fields
  # Includes comprehensive profile fields and notification preferences
  def edit
    # Edit user profile form
    # Form includes personal info, social links, preferences, and avatar upload
    # EmailChangeProtection will handle any email change attempts securely
  end

  # PATCH/PUT /users/profile
  # Update user profile with submitted data and recalculate completion
  # Handles validation errors and profile completion tracking
  def update
    if @user.update(profile_params)
      # Calculate profile completion after update
      # This updates the profile_completion_percentage based on filled fields
      @user.calculate_profile_completion
      redirect_to users_profile_path(@user), notice: "Profile updated successfully."
    else
      # Re-render edit form with validation errors
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # SECURITY: Ensure users can only access and modify their own profile
  # Prevents profile access/modification attempts via URL manipulation
  def set_user
    @user = current_user
    # Ensure user can only access their own profile
    # Protects against URL manipulation attacks (e.g., /users/profile/123)
    redirect_to root_path, alert: "Access denied." if params[:id] && params[:id].to_i != current_user.id
  end

  # SECURITY: Define permitted parameters for profile updates with email protection
  # EmailChangeProtection concern handles email changes securely
  def profile_params
    # EmailChangeProtection concern will intercept and handle email change attempts
    # This prevents unauthorized account takeover via profile updates
    permitted_attributes = [
      # Basic personal information
      :first_name, :last_name, :bio, :phone_number,

      # Avatar and image handling
      :avatar_url, :avatar,

      # Localization and preferences
      :timezone, :locale, :profile_visibility,

      # Professional/social media links
      :linkedin_url, :twitter_url, :github_url, :website_url,

      # Notification preferences (nested hash)
      notification_preferences: {}
    ]

    # ADMIN PRIVILEGE: Allow super admins to change their email directly
    # Bypasses the EmailChangeRequest workflow for administrative efficiency
    # Only super admins have this privilege due to their elevated security clearance
    permitted_attributes << :email if current_user&.super_admin?

    params.require(:user).permit(permitted_attributes)
  end
end
