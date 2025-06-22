class Admin::Super::PlansController < Admin::Super::BaseController
  before_action :set_plan, only: [ :show, :edit, :update, :destroy ]

  def index
    @plans = policy_scope(Plan).order(:plan_segment, :amount_cents)
    @pagy, @plans = pagy(@plans)
    authorize @plans
  end

  def show
    authorize @plan
  end

  def new
    @plan = Plan.new
    authorize @plan
  end

  def create
    @plan = Plan.new(plan_params)
    authorize @plan

    if @plan.save
      redirect_to admin_super_plans_path, notice: "Plan was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @plan
  end

  def update
    authorize @plan

    if @plan.update(plan_params)
      redirect_to admin_super_plans_path, notice: "Plan was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @plan
    @plan.destroy
    redirect_to admin_super_plans_path, notice: "Plan was successfully deleted."
  end

  private

  def set_plan
    @plan = Plan.find(params[:id])
  end

  def plan_params
    params.require(:plan).permit(
      :name,
      :plan_segment,
      :stripe_price_id,
      :amount_cents,
      :interval,
      :max_team_members,
      :active,
      features: []
    )
  end
end
