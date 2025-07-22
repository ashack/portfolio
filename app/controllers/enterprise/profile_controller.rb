# Enterprise::ProfileController
#
# Manages individual user profiles within enterprise organizations in the triple-track SaaS system.
# Handles personal profile management for enterprise users while maintaining enterprise context
# and isolation from direct user and team user profile management.
#
# **Access Control:**
# - Available to ALL enterprise users (both admins and members)
# - Users can only edit their own profiles (no cross-user profile editing)
# - Inherits authentication from ApplicationController
# - Enterprise user validation prevents non-enterprise access
#
# **Profile Management vs Other Systems:**
# - Enterprise user profiles are separate from direct user profiles (/dashboard/profile)
# - Different from team user profiles (/teams/:slug/profile)
# - Enterprise context maintained via enterprise_group_slug in URLs
# - Profile data shared across enterprise but isolated from other user types
#
# **Email Change Security:**
# - Integrates EmailChangeProtection concern for secure email changes
# - Email changes require approval workflow (not immediate)
# - Prevents unauthorized email changes and account takeovers
# - Maintains audit trail for email change requests
#
# **Profile Features:**
# - Personal information (name, bio, contact details)
# - Avatar and profile image management
# - Social media links and professional URLs
# - Timezone and locale preferences
# - Notification preferences (enterprise-specific)
# - Profile completion tracking and scoring
#
# **Enterprise Integration:**
# - Profile visibility controlled by enterprise settings
# - Enterprise branding and theme (purple color scheme)
# - Enterprise group context for navigation and URLs
# - Integration with enterprise member directory
#
# **URL Structure:**
# Routes scoped under /enterprise/:enterprise_group_slug/profile/
# - Maintains enterprise context in all profile operations
# - Multi-tenant profile management via enterprise group slug
class Enterprise::ProfileController < ApplicationController
  # Include email change protection for secure email updates
  include EmailChangeProtection

  # Ensure user is authenticated before profile access
  before_action :authenticate_user!
  
  # Restrict access to enterprise users only
  before_action :require_enterprise_user!
  
  # Set enterprise group context for profile operations
  before_action :set_enterprise_group
  
  # Skip Pundit authorization (users manage their own profiles)
  skip_after_action :verify_authorized

  # Displays current user's profile within enterprise context
  #
  # **Functionality:**
  # - Shows complete user profile information
  # - Displays enterprise group context and branding
  # - Includes profile completion score and recommendations
  # - Shows enterprise-specific profile fields
  #
  # **Access:**
  # - Enterprise users can view their own profile only
  # - Profile visibility controlled by enterprise settings
  # - Enterprise group context maintained in URLs
  def show
    @user = current_user
  end

  # Profile editing form for enterprise users
  #
  # **Features:**
  # - Complete profile editing interface
  # - Enterprise-themed form styling
  # - Avatar upload and management
  # - Social media and professional URL fields
  # - Notification preferences specific to enterprise
  #
  # **Security:**
  # - Users can only edit their own profiles
  # - Email changes handled by EmailChangeProtection concern
  # - Form validates all input according to enterprise standards
  def edit
    @user = current_user
  end

  # Updates user profile with validation and security checks
  #
  # **Update Process:**
  # 1. Validates all profile fields according to enterprise standards
  # 2. Handles email change requests through security workflow
  # 3. Updates profile completion score automatically
  # 4. Redirects to profile view with success confirmation
  #
  # **Email Change Handling:**
  # - EmailChangeProtection concern intercepts email changes
  # - Secure approval workflow prevents unauthorized changes
  # - Original email remains active during approval process
  #
  # **Profile Completion:**
  # - Automatically recalculates completion score after updates
  # - Provides recommendations for missing profile elements
  # - Affects user standing within enterprise directory
  def update
    @user = current_user
    if @user.update(user_params)
      # Calculate profile completion after update
      @user.calculate_profile_completion
      redirect_to profile_path(enterprise_group_slug: @enterprise_group.slug, id: @user), notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Validates that current user is an enterprise user
  #
  # **Validation Logic:**
  # - Only users with user_type: 'enterprise' can access profiles
  # - Direct users are blocked from enterprise profile access
  # - Team users are blocked from enterprise profile access
  # - Enforces triple-track system isolation
  #
  # **Redirects:**
  # - Non-enterprise users → root_path with access denied message
  def require_enterprise_user!
    redirect_to root_path, alert: "Access denied." unless current_user.enterprise?
  end

  # Sets enterprise group context for profile operations
  #
  # **Context Setting:**
  # - Uses current_user.enterprise_group association
  # - Provides enterprise context for URLs and branding
  # - Required for enterprise-specific profile features
  # - Maintains multi-tenant isolation
  def set_enterprise_group
    @enterprise_group = current_user.enterprise_group
  end

  # Strong parameters for user profile updates
  #
  # **Permitted Fields:**
  # - Personal information: first_name, last_name, bio, phone_number
  # - Avatar management: avatar_url, avatar
  # - Preferences: timezone, locale, profile_visibility
  # - Social links: linkedin_url, twitter_url, github_url, website_url
  # - Notification preferences: enterprise-specific notification settings
  #
  # **Email Handling:**
  # - Email changes handled by EmailChangeProtection concern
  # - Not included in direct parameter list (intercepted by concern)
  def user_params
    # EmailChangeProtection concern will handle email change attempts
    params.require(:user).permit(
      :first_name, :last_name, :bio, :phone_number, :avatar_url, :avatar,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url,
      notification_preferences: {}
    )
  end
end
