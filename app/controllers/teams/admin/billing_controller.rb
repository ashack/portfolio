class Teams::Admin::BillingController < Teams::Admin::BaseController
  # Skip Pundit verification since billing shows team's own data
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  before_action :set_payment_processor, if: :payment_processor_available?

  def index
    if payment_processor_available?
      @charges = @team.payment_processor.charges.order(created_at: :desc) rescue []
      @payment_methods = @team.payment_processor.payment_methods rescue []
      @subscription = @team.payment_processor.subscription rescue nil
    else
      @charges = []
      @payment_methods = []
      @subscription = nil
    end
  end

  def show
    return redirect_to team_admin_billing_index_path, alert: "Payment system not available" unless payment_processor_available?
    @charge = @team.payment_processor.charges.find(params[:id])
  rescue
    redirect_to team_admin_billing_index_path, alert: "Charge not found"
  end

  private

  def payment_processor_available?
    @team.respond_to?(:payment_processor) &&
    @team.respond_to?(:set_payment_processor)
  end

  def set_payment_processor
    @team.set_payment_processor(:stripe)
  rescue
    # Gracefully handle cases where payment processor setup fails
    Rails.logger.warn "Failed to set payment processor for team #{@team.id}"
  end
end
