class Users::BillingController < Users::BaseController
  before_action :set_payment_processor

  def index
    @charges = current_user.payment_processor.charges.order(created_at: :desc)
    @payment_methods = current_user.payment_processor.payment_methods
  end

  def show
    @charge = current_user.payment_processor.charges.find(params[:id])
  end

  def edit
    @payment_method = current_user.payment_processor.payment_methods.find(params[:id])
  end

  def update
    @payment_method = current_user.payment_processor.payment_methods.find(params[:id])

    if @payment_method.update(payment_method_params)
      redirect_to users_billing_index_path, notice: "Payment method was successfully updated."
    else
      render :edit
    end
  end

  private

  def set_payment_processor
    current_user.set_payment_processor(:stripe)
  end

  def payment_method_params
    params.require(:payment_method).permit(:default)
  end
end
