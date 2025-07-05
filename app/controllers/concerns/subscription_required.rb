# SubscriptionRequired Concern
# Provides subscription checking functionality for controllers
# Automatically bypasses checks for super admins and site admins
#
# Usage:
#   class MyController < ApplicationController
#     include SubscriptionRequired
#     # All actions will require subscription
#   end
#
#   class MyController < ApplicationController
#     include SubscriptionRequired
#     skip_before_action :require_active_subscription, only: [:index, :show]
#     # Only specific actions require subscription
#   end
#
module SubscriptionRequired
  extend ActiveSupport::Concern

  included do
    before_action :require_active_subscription
  end

  private

  def require_active_subscription
    # Skip subscription check for admins
    return if current_user&.super_admin? || current_user&.site_admin?

    # Check if user has active subscription
    unless has_active_subscription?
      redirect_to subscription_required_redirect_path,
                  alert: subscription_required_message
    end
  end

  def has_active_subscription?
    subscribable = current_subscribable
    return false unless subscribable

    subscribable.respond_to?(:subscribed?) && subscribable.subscribed?
  end

  # Override in controllers to specify what should have a subscription
  # e.g., current_user, current_team, current_enterprise_group
  def current_subscribable
    current_user
  end

  # Override in controllers to specify where to redirect
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

  # Override in controllers to customize the message
  def subscription_required_message
    "An active subscription is required to access this feature."
  end
end
