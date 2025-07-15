class Users::BillingController < Users::BaseController
  # Skip Pundit verification since billing shows user's own data
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  before_action :set_payment_processor, if: :payment_processor_available?

  def index
    if payment_processor_available?
      charges = current_user.payment_processor.charges.order(created_at: :desc)
      @pagy, @charges = pagy(charges, items: 20)
      @payment_methods = current_user.payment_processor.payment_methods
    else
      @charges = []
      @payment_methods = []
    end
  end

  def show
    return redirect_to users_billing_index_path, alert: "Payment system not available" unless payment_processor_available?
    @charge = current_user.payment_processor.charges.find(params[:id])
  end

  def edit
    return redirect_to users_billing_index_path, alert: "Payment system not available" unless payment_processor_available?
    @payment_method = current_user.payment_processor.payment_methods.find(params[:id])
  end

  def update
    return redirect_to users_billing_index_path, alert: "Payment system not available" unless payment_processor_available?
    @payment_method = current_user.payment_processor.payment_methods.find(params[:id])

    if @payment_method.update(payment_method_params)
      redirect_to users_billing_index_path, notice: "Payment method was successfully updated."
    else
      render :edit
    end
  end

  private

  def payment_processor_available?
    current_user.respond_to?(:payment_processor) &&
    current_user.respond_to?(:set_payment_processor)
  end

  def set_payment_processor
    current_user.set_payment_processor(:stripe)
  end

  def payment_method_params
    params.require(:payment_method).permit(:default)
  end
end
