class Users::SubscriptionsController < Users::BaseController
  # Use admin layout for admin users
  layout :determine_layout

  before_action :set_current_plan
  before_action :set_available_plans, only: [ :show, :edit ]
  before_action :set_new_plan, only: [ :update ]

  def show
    authorize :subscription, :show?
  end

  def edit
    authorize :subscription, :edit?
  end

  def update
    authorize :subscription, :update?

    if @new_plan
      if change_plan_to(@new_plan)
        redirect_to users_subscription_path, notice: "Your plan has been successfully changed to #{@new_plan.name}."
      else
        redirect_to edit_users_subscription_path, alert: "Unable to change plan. Please try again."
      end
    else
      redirect_to edit_users_subscription_path, alert: "Please select a valid plan."
    end
  end

  def destroy
    authorize :subscription, :destroy?

    # Find the free plan
    free_plan = Plan.find_by(plan_segment: "individual", amount_cents: 0, active: true)

    if free_plan && current_user.plan != free_plan
      if change_plan_to(free_plan)
        redirect_to users_subscription_path, notice: "Your subscription has been cancelled. You are now on the free plan."
      else
        redirect_to users_subscription_path, alert: "Unable to cancel subscription. Please try again."
      end
    else
      redirect_to users_subscription_path, alert: "You are already on the free plan."
    end
  end

  private

  def set_current_plan
    @current_plan = current_user.plan
  end

  def set_available_plans
    @available_plans = Plan.available_for_signup
                          .by_segment("individual")
                          .where.not(id: @current_plan&.id)
                          .order(:amount_cents)
  end

  def set_new_plan
    @new_plan = Plan.find_by(id: params[:plan_id])
  end

  def change_plan_to(new_plan)
    current_user.update(plan: new_plan)
  end

  def determine_layout
    if current_user&.super_admin? || current_user&.site_admin?
      "admin"
    else
      "user"
    end
  end
end
