# Billing controller for direct users
# Manages personal Stripe subscriptions and payment methods via Pay gem
# Only accessible to direct users with individual billing
class Users::BillingController < Users::BaseController
  # Skip Pundit verification - billing shows user's own payment data
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  # Set up Stripe payment processor if available
  before_action :set_payment_processor, if: :payment_processor_available?

  # GET /users/billing
  # Display billing history and payment methods
  # Shows charges, invoices, and payment methods from Stripe
  def index
    if payment_processor_available?
      # Load user's payment history from Stripe via Pay gem
      charges = current_user.payment_processor.charges.order(created_at: :desc)
      @pagy, @charges = pagy(charges, items: 20) # Paginate for performance
      @payment_methods = current_user.payment_processor.payment_methods
    else
      # Handle case where payment processor isn't set up yet
      @charges = []
      @payment_methods = []
    end
  end

  # GET /users/billing/:id
  # Show details for specific charge/invoice
  def show
    return redirect_to users_billing_index_path, alert: "Payment system not available" unless payment_processor_available?
    # Load specific charge from user's payment history
    @charge = current_user.payment_processor.charges.find(params[:id])
  end

  # GET /users/billing/:id/edit
  # Edit payment method settings (e.g., set as default)
  def edit
    return redirect_to users_billing_index_path, alert: "Payment system not available" unless payment_processor_available?
    # Load specific payment method for editing
    @payment_method = current_user.payment_processor.payment_methods.find(params[:id])
  end

  # PATCH /users/billing/:id
  # Update payment method settings
  def update
    return redirect_to users_billing_index_path, alert: "Payment system not available" unless payment_processor_available?
    # Load and update payment method
    @payment_method = current_user.payment_processor.payment_methods.find(params[:id])

    if @payment_method.update(payment_method_params)
      redirect_to users_billing_index_path, notice: "Payment method was successfully updated."
    else
      # Re-render edit form with validation errors
      render :edit
    end
  end

  private

  # Check if Pay gem payment processor methods are available
  # Prevents errors if Pay gem not properly integrated
  def payment_processor_available?
    current_user.respond_to?(:payment_processor) &&
    current_user.respond_to?(:set_payment_processor)
  end

  # Initialize Stripe as the payment processor for this user
  # Pay gem supports multiple processors, we use Stripe
  def set_payment_processor
    current_user.set_payment_processor(:stripe)
  end

  # Strong parameters for payment method updates
  # Only allow setting default status for security
  def payment_method_params
    params.require(:payment_method).permit(:default)
  end
end
