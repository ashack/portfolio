class Enterprise::BillingController < Enterprise::BaseController
  before_action :require_admin!
  skip_after_action :verify_policy_scoped, only: [ :index ]

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

  def show
    @invoice = @enterprise_group.charges.find(params[:id])
  end

  def update_payment_method
    if @enterprise_group.update_payment_method(params[:payment_method_id])
      redirect_to billing_index_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Payment method updated successfully"
    else
      redirect_to billing_index_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Failed to update payment method"
    end
  end

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

  def require_admin!
    unless current_user.enterprise_admin?
      redirect_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "You don't have permission to access billing"
    end
  end
end
