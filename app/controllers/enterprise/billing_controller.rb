# Enterprise::BillingController
#
# Manages billing and subscription operations for enterprise organizations within the
# triple-track SaaS system. This controller handles Stripe integration through the Pay gem
# for enterprise-level billing that is completely separate from direct user and team billing.
#
# **Access Control:**
# - RESTRICTED to Enterprise Admins only (enterprise_group_role: 'admin')
# - Enterprise Members cannot access billing information
# - Inherits enterprise user validation from Enterprise::BaseController
#
# **Enterprise Billing vs Other Systems:**
# - Enterprise billing is isolated from direct user billing (individual Stripe subscriptions)
# - Enterprise billing is separate from team billing (team-based Stripe subscriptions)  
# - Each enterprise group has its own Pay::Billable implementation
# - Custom pricing and enterprise-specific plans available
#
# **Pay Gem Integration:**
# - Uses Pay gem for Stripe subscription management
# - Enterprise groups are Pay::Billable entities
# - Supports subscriptions, payment methods, charges, and invoices
# - Handles Pay gem initialization gracefully for development/testing
#
# **Billing Features:**
# - View active subscriptions and billing history
# - Update payment methods
# - Cancel subscriptions (enterprise admin only)
# - Download invoices and billing statements
# - Manage enterprise-specific pricing plans
#
# **URL Structure:**
# All routes are scoped under /enterprise/:enterprise_group_slug/billing/
# - Enforces multi-tenant billing isolation
# - Enterprise group slug identifies the billing entity
class Enterprise::BillingController < Enterprise::BaseController
  # Restrict all billing actions to enterprise admins only
  before_action :require_admin!
  
  # Skip Pundit policy verification for index action (handled by admin check)
  skip_after_action :verify_policy_scoped, only: [ :index ]

  # Main billing dashboard showing subscription status and billing history
  #
  # **Displays:**
  # - Active subscription details (plan, status, next billing date)
  # - Default payment method information  
  # - Recent invoices and charges (paginated)
  # - Upcoming invoice preview (if available)
  #
  # **Pay Gem Safety:**
  # - Checks if Pay gem methods are available before calling
  # - Gracefully handles cases where Pay is not fully initialized
  # - Prevents errors in development/testing environments
  def index
    # Get Pay subscriptions for this enterprise group
    # Handle cases where Pay gem might not be fully initialized
    if @enterprise_group.respond_to?(:subscriptions)
      @subscription = @enterprise_group.subscriptions.active.first
    end

    if @enterprise_group.respond_to?(:payment_methods)
      @payment_method = @enterprise_group.payment_methods.default.first
    end

    if @enterprise_group.respond_to?(:charges)
      invoices = @enterprise_group.charges.order(created_at: :desc)
      @pagy, @invoices = pagy(invoices, items: 20)
    else
      @invoices = []
    end

    # Note: upcoming_invoice is a Stripe-specific feature that requires additional setup
    @upcoming_invoice = nil
  end

  # Shows individual invoice/charge details
  #
  # **Features:**
  # - Detailed invoice information
  # - Download invoice PDF
  # - Payment status and dates
  # - Line items and tax information
  def show
    @invoice = @enterprise_group.charges.find(params[:id])
  end

  # Updates the default payment method for the enterprise group
  #
  # **Business Logic:**
  # - Only enterprise admins can update payment methods
  # - Updates Stripe customer's default payment method
  # - Affects all future subscription charges
  # - Validates payment method belongs to the enterprise group
  #
  # **Integration:**
  # - Uses Pay gem's payment method management
  # - Syncs with Stripe customer object
  # - Handles Stripe API errors gracefully
  def update_payment_method
    if @enterprise_group.update_payment_method(params[:payment_method_id])
      redirect_to billing_index_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Payment method updated successfully"
    else
      redirect_to billing_index_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Failed to update payment method"
    end
  end

  # Cancels the enterprise group's active subscription
  #
  # **Business Logic:**
  # - Only enterprise admins can cancel subscriptions
  # - Cancels subscription at period end (no immediate termination)
  # - Maintains access until current billing period expires
  # - Prevents accidental service interruption
  #
  # **Effects:**
  # - Subscription status changes to 'canceled' 
  # - No future charges will be processed
  # - Enterprise features remain active until period end
  # - Can be reactivated before period end
  def cancel_subscription
    if @enterprise_group.subscription&.cancel
      redirect_to billing_index_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Subscription cancelled"
    else
      redirect_to billing_index_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Failed to cancel subscription"
    end
  end

  private

  # Restricts access to enterprise administrators only
  #
  # **Authorization Logic:**
  # - Checks current_user.enterprise_admin? method
  # - Enterprise members (non-admin) are blocked from billing access
  # - Maintains separation of concerns in enterprise management
  # - Prevents unauthorized access to sensitive billing information
  #
  # **Redirects:**
  # - Non-admin enterprise users → enterprise dashboard with error message
  def require_admin!
    unless current_user.enterprise_admin?
      redirect_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "You don't have permission to access billing"
    end
  end
end
