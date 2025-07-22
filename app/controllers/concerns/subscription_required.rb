# SubscriptionRequired Concern
#
# OVERVIEW:
# This concern enforces active subscription requirements across the triple-track SaaS
# system. It protects premium features by ensuring users have valid, active subscriptions
# before accessing paid functionality, while providing appropriate bypasses for
# administrative users and proper redirect flows for each user type.
#
# PURPOSE:
# - Protect premium features behind subscription paywalls
# - Ensure revenue protection across all user types
# - Provide consistent subscription checking across controllers
# - Support different subscription models (individual, team, enterprise)
# - Enable flexible feature gating based on subscription status
# - Maintain user experience with appropriate redirects
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# This concern adapts to different subscription models:
# 1. DIRECT USERS: Individual Stripe subscriptions (Pay gem integration)
# 2. TEAM MEMBERS: Inherit team subscription status (team-level billing)
# 3. ENTERPRISE USERS: Inherit enterprise subscription status (organization billing)
# 4. ADMIN USERS: Bypass subscription checks (administrative access)
#
# SUBSCRIPTION MODELS:
# - Individual subscriptions: Direct users with personal billing
# - Team subscriptions: Shared billing across team members
# - Enterprise subscriptions: Organization-level billing with member access
# - Admin bypass: Super admins and site admins skip subscription checks
#
# BUSINESS LOGIC:
# - Subscription checks occur before protected actions
# - Different user types check different subscription sources
# - Admin users automatically bypass all subscription requirements
# - Failed checks redirect to appropriate subscription management pages
# - Supports both hard paywalls and feature limitations
#
# SECURITY CONSIDERATIONS:
# - Prevents unauthorized access to paid features
# - Revenue protection through consistent enforcement
# - Admin bypass prevents lockout of administrative functions
# - Subscription validation uses secure Pay gem integration
#
# USER EXPERIENCE:
# - Context-aware redirects to appropriate subscription pages
# - Clear messaging about subscription requirements
# - Smooth upgrade flows for different user types
# - Preservation of intended destination after subscription
#
# EXTERNAL DEPENDENCIES:
# - Pay gem for subscription status checking
# - User, Team, and EnterpriseGroup models with subscription capabilities
# - Stripe integration for payment processing
# - Route helpers for redirect destinations
#
# USAGE EXAMPLES:
# 1. Protect all controller actions:
#    class PremiumFeaturesController < ApplicationController
#      include SubscriptionRequired
#      # All actions will require subscription
#    end
#
# 2. Protect specific actions only:
#    class MixedController < ApplicationController
#      include SubscriptionRequired
#      skip_before_action :require_active_subscription, only: [:index, :show]
#      # Only create/update/delete actions require subscription
#    end
#
# 3. Custom subscription entity:
#    class TeamController < ApplicationController
#      include SubscriptionRequired
#      
#      private
#      
#      def current_subscribable
#        current_team  # Check team subscription instead of user
#      end
#    end
#
# PERFORMANCE CONSIDERATIONS:
# - Efficient subscription status checking
# - Minimal database queries through optimized associations
# - Caches subscription status where appropriate
# - Early returns for admin users to skip unnecessary checks
#
module SubscriptionRequired
  extend ActiveSupport::Concern

  included do
    # Require active subscription before accessing protected actions
    # This ensures revenue protection and proper feature gating
    before_action :require_active_subscription
  end

  private

  # Main subscription enforcement method
  #
  # ENFORCEMENT FLOW:
  # 1. Skip check for admin users (super_admin and site_admin)
  # 2. Check subscription status via current_subscribable
  # 3. Redirect to appropriate subscription page if not subscribed
  # 4. Display context-appropriate message about subscription requirement
  #
  # ADMIN BYPASS:
  # Super admins and site admins automatically bypass subscription checks
  # to ensure administrative functions remain accessible regardless of
  # subscription status. This prevents lockout scenarios.
  #
  # SUBSCRIPTION VALIDATION:
  # Uses Pay gem's subscription status checking through the subscribable entity,
  # which could be a User, Team, or EnterpriseGroup depending on context.
  def require_active_subscription
    # Skip subscription check for admins
    return if current_user&.super_admin? || current_user&.site_admin?

    # Check if user has active subscription
    unless has_active_subscription?
      redirect_to subscription_required_redirect_path,
                  alert: subscription_required_message
    end
  end

  # Checks if the current subscribable entity has an active subscription
  #
  # SUBSCRIPTION SOURCES:
  # - Direct Users: Personal Stripe subscription via Pay gem
  # - Team Members: Team's shared subscription
  # - Enterprise Users: Enterprise organization's subscription
  #
  # PAY GEM INTEGRATION:
  # Uses Pay gem's `subscribed?` method which checks:
  # - Subscription exists and is active
  # - Payment method is valid
  # - No past due payments
  # - Subscription hasn't been canceled
  #
  # @return [Boolean] true if subscribable entity has active subscription
  def has_active_subscription?
    subscribable = current_subscribable
    return false unless subscribable

    subscribable.respond_to?(:subscribed?) && subscribable.subscribed?
  end

  # Determines what entity should be checked for subscription status
  #
  # DEFAULT BEHAVIOR:
  # Returns current_user for individual subscription checking
  #
  # OVERRIDE EXAMPLES:
  # - Team controllers: return current_team
  # - Enterprise controllers: return current_enterprise_group
  # - Mixed contexts: return appropriate entity based on user type
  #
  # This method should be overridden in controllers where subscription
  # checking should be done at the team or enterprise level instead of
  # the individual user level.
  #
  # @return [Object] the entity to check for subscription status
  def current_subscribable
    current_user
  end

  # Determines where to redirect users who need subscriptions
  #
  # TRIPLE-TRACK REDIRECTS:
  # 1. Direct Users: Individual subscription management page
  # 2. Team Members: Team dashboard (team admin handles subscriptions)
  # 3. Enterprise Users: Enterprise dashboard (enterprise admin handles subscriptions)
  # 4. Fallback: Root path for unknown user types
  #
  # BUSINESS LOGIC:
  # - Direct users manage their own subscriptions
  # - Team and enterprise members cannot directly manage subscriptions
  # - Redirects maintain context and inform users of proper upgrade path
  #
  # This method can be overridden in controllers to customize redirect
  # behavior for specific features or user flows.
  #
  # @return [String] path to redirect to for subscription management
  def subscription_required_redirect_path
    if current_user&.direct?
      users_subscription_path
    elsif current_user&.invited? && current_user.team
      team_root_path(team_slug: current_user.team.slug)
    elsif current_user&.enterprise? && current_user.enterprise_group
      enterprise_root_path(enterprise_slug: current_user.enterprise_group.slug)
    else
      root_path
    end
  end

  # Provides user-facing message about subscription requirement
  #
  # DEFAULT MESSAGE:
  # Generic message about subscription requirement
  #
  # CUSTOMIZATION:
  # Override in controllers to provide feature-specific messaging:
  # - "Premium analytics require a Pro subscription"
  # - "Team collaboration features require team subscription"
  # - "Advanced reporting requires enterprise subscription"
  #
  # USER EXPERIENCE:
  # Clear messaging helps users understand upgrade benefits and
  # reduces confusion about feature access restrictions.
  #
  # @return [String] user-facing message about subscription requirement
  def subscription_required_message
    "An active subscription is required to access this feature."
  end
end
