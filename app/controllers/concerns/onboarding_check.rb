# OnboardingCheck Concern
#
# OVERVIEW:
# This concern enforces the onboarding workflow for Direct Users in the triple-track
# SaaS system. It ensures that Direct Users complete the plan selection and setup
# process before accessing application features, maintaining a smooth user experience
# and proper subscription management.
#
# PURPOSE:
# - Enforce completion of onboarding workflow for Direct Users
# - Ensure proper plan selection before feature access
# - Guide new users through the setup process
# - Prevent access to features without subscription setup
# - Maintain clean user experience with proper redirects
#
# TRIPLE-TRACK SYSTEM INTEGRATION:
# This concern ONLY applies to Direct Users:
# 1. DIRECT USERS: Must complete onboarding including plan selection
# 2. INVITED USERS: Skip onboarding (join through team invitation)
# 3. ENTERPRISE USERS: Skip onboarding (join through enterprise invitation)
# 4. ADMIN USERS: Skip onboarding (administrative accounts)
#
# ONBOARDING WORKFLOW:
# The onboarding process for Direct Users includes:
# 1. Email verification (required first)
# 2. Plan selection (individual or team plans)
# 3. Payment setup (for paid plans)
# 4. Profile completion
# 5. Feature introduction/tutorial
# 6. Onboarding completion flag set
#
# BUSINESS LOGIC:
# - Only Direct Users go through onboarding
# - Email verification must be completed first
# - Users without plans are redirected to plan selection
# - Onboarding completion tracked via database flag
# - Essential paths (logout, assets) remain accessible
#
# USER EXPERIENCE CONSIDERATIONS:
# - Graceful redirects maintain user context
# - Clear separation between required and optional steps
# - Progressive disclosure of features post-onboarding
# - Preservation of intended destination after completion
#
# EXTERNAL DEPENDENCIES:
# - User model with onboarding_completed flag
# - Users::OnboardingController for the onboarding flow
# - Devise for authentication and email confirmation
# - Plan model for subscription management
#
# USAGE EXAMPLES:
# 1. Include in application controller for global enforcement:
#    class ApplicationController < ActionController::Base
#      include OnboardingCheck
#    end
#
# 2. Include selectively in user-facing controllers:
#    class DashboardController < ApplicationController
#      include OnboardingCheck
#    end
#
# 3. Skip for specific actions that shouldn't require onboarding:
#    class ApiController < ApplicationController
#      include OnboardingCheck
#      skip_before_action :check_onboarding_status
#    end
#
# PERFORMANCE CONSIDERATIONS:
# - Early returns minimize processing overhead
# - Database queries only when necessary
# - Efficient path checking for skip conditions
# - Minimal impact on non-Direct User requests
#
module OnboardingCheck
  extend ActiveSupport::Concern

  included do
    # Check onboarding status before each action to enforce completion
    # This ensures users complete setup before accessing features
    before_action :check_onboarding_status
  end

  private

  # Main onboarding enforcement method
  #
  # ENFORCEMENT FLOW:
  # 1. Skip if user not signed in (anonymous access allowed)
  # 2. Skip if user is not Direct type (only Direct Users need onboarding)
  # 3. Skip if onboarding already completed
  # 4. Skip if email not confirmed (email verification takes precedence)
  # 5. Skip for specific controllers/paths that should remain accessible
  # 6. Redirect to onboarding if user lacks required plan setup
  #
  # REDIRECT LOGIC:
  # Users are redirected to onboarding when:
  # - They are Direct Users
  # - Email is confirmed
  # - Onboarding not completed
  # - No plan selected (plan_id is nil)
  # - Not already in onboarding flow
  #
  # SECURITY NOTE: This prevents access to paid features without
  # proper subscription setup, supporting revenue protection.
  def check_onboarding_status
    return unless user_signed_in?
    return unless current_user.direct?
    return if current_user.onboarding_completed?

    # Skip onboarding check for unconfirmed users - they need to verify email first
    return unless current_user.confirmed?

    # Skip onboarding check for certain controllers/actions
    return if skip_onboarding_check?

    # If user doesn't have a plan and hasn't completed onboarding, redirect
    if current_user.plan_id.nil?
      redirect_to users_onboarding_path unless request.path.start_with?("/users/onboarding")
    end
  end

  # Determines when to skip onboarding checks
  #
  # SKIP CONDITIONS:
  # 1. Devise controllers (authentication flows)
  # 2. Onboarding controller itself (prevents redirect loops)
  # 3. Email verification controller (email confirmation takes precedence)
  # 4. Essential user paths (logout, onboarding, verification)
  # 5. Asset and system paths (CSS, JS, Rails internal routes)
  #
  # PATH-BASED SKIPPING:
  # - /users/onboarding/* - Onboarding flow paths
  # - /users/email_verification/* - Email confirmation paths  
  # - /users/sign_out - Logout functionality
  # - /assets/* - Static assets (CSS, JS, images)
  # - /rails/* - Rails internal routes (Active Storage, etc.)
  #
  # CONTROLLER-BASED SKIPPING:
  # - Devise controllers for authentication
  # - Onboarding controller to prevent redirect loops
  # - Email verification controller for email confirmation
  #
  # @return [Boolean] true if onboarding check should be skipped
  def skip_onboarding_check?
    # Skip for devise controllers
    devise_controller? ||
    # Skip for onboarding controller itself
    controller_name == "onboarding" ||
    # Skip for email verification controller
    controller_name == "email_verification" ||
    # Skip for specific paths that should be accessible
    request.path.start_with?("/users/onboarding") ||
    request.path.start_with?("/users/email_verification") ||
    request.path == "/users/sign_out" ||
    # Skip for assets and other non-app paths
    request.path.start_with?("/assets") ||
    request.path.start_with?("/rails")
  end
end
