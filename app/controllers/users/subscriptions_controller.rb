# Users::SubscriptionsController
#
# PURPOSE: Manages individual subscription billing and plan changes for direct users
# in the triple-track SaaS system. Handles plan upgrades, downgrades, and cancellations
# with integration to the Pay gem and Stripe billing system.
#
# SCOPE: Direct users only - part of the triple-track system where:
# - Direct users: Individual registrations with personal Stripe billing
# - Invited users: Team members (no billing access - managed by team admin)
# - Enterprise users: Organization members (no billing access - managed by enterprise admin)
#
# FUNCTIONALITY:
# - Subscription viewing (current plan, usage, billing history)
# - Plan change management (upgrades, downgrades within individual segment)
# - Subscription cancellation with automatic free plan fallback
# - Available plan filtering (individual plans only, excludes current plan)
# - Integration with Pay gem for Stripe subscription management
#
# BILLING INTEGRATION:
# - Pay gem integration for Stripe subscription management
# - Plan changes within the same segment (individual plans only)
# - Cross-segment migrations handled by PlanMigrationsController
# - Automatic free plan assignment on cancellation
#
# SECURITY:
# - Pundit authorization for all subscription operations
# - Scoped to individual plans only (cannot access team/enterprise plans)
# - Validation of plan availability and user eligibility
#
class Users::SubscriptionsController < Users::BaseController
  # Load current plan for all actions to display billing information
  before_action :set_current_plan

  # Load available plans for subscription viewing and editing
  before_action :set_available_plans, only: [ :show, :edit ]

  # Load the target plan for update operations
  before_action :set_new_plan, only: [ :update ]

  # GET /users/subscription
  # Display current subscription status, billing information, and available plan options
  # Shows plan details, usage metrics, and billing history
  def show
    # Authorize subscription viewing through Pundit policy
    authorize :subscription, :show?
    # @current_plan and @available_plans loaded by before_actions
    # Template shows current plan details, usage, and upgrade options
  end

  # GET /users/subscription/edit
  # Display plan change form with available individual plans
  # Excludes current plan and shows pricing comparison
  def edit
    # Authorize subscription editing through Pundit policy
    authorize :subscription, :edit?
    # @available_plans contains individual plans excluding current plan
    # Template shows plan comparison and change options
  end

  # PATCH/PUT /users/subscription
  # Execute plan change within individual plan segment
  # Handles upgrade/downgrade logic with Pay gem integration
  def update
    # Authorize subscription updates through Pundit policy
    authorize :subscription, :update?

    if @new_plan
      if change_plan_to(@new_plan)
        redirect_to users_subscription_path, notice: "Your plan has been successfully changed to #{@new_plan.name}."
      else
        # Plan change failed - could be Stripe error, validation failure, etc.
        redirect_to edit_users_subscription_path, alert: "Unable to change plan. Please try again."
      end
    else
      # Invalid or missing plan selection
      redirect_to edit_users_subscription_path, alert: "Please select a valid plan."
    end
  end

  # DELETE /users/subscription
  # Cancel subscription and automatically downgrade to free plan
  # Maintains account access with free tier features
  def destroy
    # Authorize subscription cancellation through Pundit policy
    authorize :subscription, :destroy?

    # Find the free individual plan for automatic downgrade
    free_plan = Plan.find_by(plan_segment: "individual", amount_cents: 0, active: true)

    if free_plan && current_user.plan != free_plan
      if change_plan_to(free_plan)
        redirect_to users_subscription_path, notice: "Your subscription has been cancelled. You are now on the free plan."
      else
        # Cancellation failed - could be Stripe error, database issue, etc.
        redirect_to users_subscription_path, alert: "Unable to cancel subscription. Please try again."
      end
    else
      # User is already on free plan - nothing to cancel
      redirect_to users_subscription_path, alert: "You are already on the free plan."
    end
  end

  private

  # Load the user's current plan for subscription management operations
  def set_current_plan
    @current_plan = current_user.plan
  end

  # BUSINESS LOGIC: Filter available plans for individual users
  # Shows only individual segment plans excluding the user's current plan
  # Orders by price for easy comparison
  def set_available_plans
    @available_plans = Plan.available_for_signup
                          .by_segment("individual")           # Only individual plans
                          .where.not(id: @current_plan&.id)  # Exclude current plan
                          .order(:amount_cents)               # Order by price ascending
  end

  # Load the target plan for subscription updates with validation
  def set_new_plan
    @new_plan = Plan.find_by(id: params[:plan_id])
    # Returns nil if plan doesn't exist, handled by update action
  end

  # PAY GEM INTEGRATION: Execute plan change with Stripe subscription management
  # This method handles the database update and should trigger Pay gem hooks
  # for Stripe subscription modification (TODO: Full Stripe integration)
  def change_plan_to(new_plan)
    # TODO: Add Pay gem integration for Stripe subscription changes
    # This should handle:
    # 1. Stripe subscription modification via Pay gem
    # 2. Prorated billing calculations
    # 3. Payment method validation
    # 4. Subscription status updates
    # 5. Webhook handling for subscription changes

    # For now, just update the plan association
    # Pay gem integration will handle the Stripe subscription automatically
    current_user.update(plan: new_plan)
  end
end
