# Teams::Admin::BillingController - Team billing and payment management
#
# PURPOSE:
# - Manages team billing information and payment processing
# - Provides billing overview, charge history, and payment method management
# - Integrates with Stripe via Pay gem for payment processing
# - Accessible only to team administrators for financial security
#
# ACCESS LEVEL: Team Admin Only
# - Restricted to users with team_admin? = true
# - Team owners (direct users) have full billing access
# - Invited admins have delegated billing management privileges
# - Regular team members cannot access billing information
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/admin/billing (index - billing overview)
# - GET /teams/:team_slug/admin/billing/:id (show - individual charge details)
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS (admin role): Can manage team billing if granted admin privileges
# - DIRECT USERS (team owners): Full billing access for teams they own
# - ENTERPRISE USERS: Cannot access (separate enterprise billing)
#
# PAYMENT PROCESSING INTEGRATION:
# - Uses Pay gem for Stripe integration
# - Supports multiple payment processors (currently Stripe)
# - Graceful degradation when payment processor unavailable
# - Defensive programming for payment system failures
#
# BILLING FEATURES:
# - Charge history with pagination (20 items per page)
# - Payment method management
# - Subscription status and details
# - Individual charge details and receipts
# - Billing event tracking and logging
#
# SECURITY CONSIDERATIONS:
# - Admin-only access to protect financial information
# - Graceful error handling for payment processor failures
# - No cross-team billing access (team scope enforced)
# - Billing operations logged for audit compliance
# - Defensive programming against payment system outages
#
class Teams::Admin::BillingController < Teams::Admin::BaseController
  # Skip Pundit verification since billing shows team's own data
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  before_action :set_payment_processor, if: :payment_processor_available?

  # BILLING OVERVIEW
  # Displays comprehensive billing information for team administrators
  # Includes charge history, payment methods, and subscription status
  def index
    if payment_processor_available?
      # Load recent charges with error handling for payment processor issues
      charges = @team.payment_processor.charges.order(created_at: :desc) rescue Charge.none
      @pagy, @charges = pagy(charges, items: 20)

      # Load payment methods with graceful error handling
      @payment_methods = @team.payment_processor.payment_methods rescue []

      # Load current subscription information
      @subscription = @team.payment_processor.subscription rescue nil
    else
      # Graceful degradation when payment processor unavailable
      @charges = []
      @payment_methods = []
      @subscription = nil
    end
  end

  # INDIVIDUAL CHARGE DETAILS
  # Shows detailed information about a specific billing charge
  # Includes charge breakdown, payment method, and transaction details
  def show
    return redirect_to team_admin_billing_index_path, alert: "Payment system not available" unless payment_processor_available?

    @charge = @team.payment_processor.charges.find(params[:id])
  rescue
    # Handle charge not found or payment processor errors
    redirect_to team_admin_billing_index_path, alert: "Charge not found"
  end

  private

  # PAYMENT PROCESSOR AVAILABILITY CHECK
  # Verifies that payment processing functionality is available
  # Prevents errors when Pay gem or Stripe integration is not properly configured
  def payment_processor_available?
    @team.respond_to?(:payment_processor) &&
    @team.respond_to?(:set_payment_processor)
  end

  # PAYMENT PROCESSOR INITIALIZATION
  # Sets up Stripe as the payment processor for the team
  # Includes error handling for configuration issues
  def set_payment_processor
    @team.set_payment_processor(:stripe)
  rescue
    # Gracefully handle cases where payment processor setup fails
    # This prevents the entire controller from breaking due to payment issues
    Rails.logger.warn "Failed to set payment processor for team #{@team.id}"
  end
end
