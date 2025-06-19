class Users::PlanMigrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_direct_user
  before_action :set_current_plan

  def new
    @target_plan = Plan.find(params[:plan_id])
    authorize :plan_migration, :create?

    if @target_plan.plan_segment == @current_plan&.plan_segment
      redirect_to users_subscription_path, alert: "Please use the regular plan change for same type plans."
      return
    end

    @requires_team_creation = @target_plan.plan_segment == "team" && !current_user.owns_team?
  end

  def create
    @target_plan = Plan.find(params[:plan_id])
    authorize :plan_migration, :create?

    case @target_plan.plan_segment
    when "team"
      migrate_to_team_plan
    when "individual"
      migrate_to_individual_plan
    else
      redirect_to users_subscription_path, alert: "Invalid plan type for migration."
    end
  end

  private

  def ensure_direct_user
    unless current_user.direct?
      redirect_to user_dashboard_path, alert: "Only direct users can migrate plans."
    end
  end

  def set_current_plan
    @current_plan = current_user.plan
  end

  def migrate_to_team_plan
    team_name = params[:team_name]

    if team_name.blank?
      redirect_to new_users_plan_migration_path(plan_id: @target_plan.id),
                  alert: "Team name is required when migrating to a team plan."
      return
    end

    ActiveRecord::Base.transaction do
      # Create team if user doesn't own one
      unless current_user.owns_team?
        team = Team.create!(
          name: team_name,
          admin: current_user,
          created_by: current_user,
          plan: determine_team_plan(@target_plan),
          status: "active",
          max_members: @target_plan.max_team_members || 5
        )

        current_user.update!(
          team: team,
          team_role: "admin",
          owns_team: true
        )
      end

      # Update user's plan
      current_user.update!(plan: @target_plan)

      # TODO: Handle Stripe subscription migration

      redirect_to user_dashboard_path,
                  notice: "Successfully migrated to #{@target_plan.name} plan with your team!"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_users_plan_migration_path(plan_id: @target_plan.id),
                alert: "Migration failed: #{e.message}"
  end

  def migrate_to_individual_plan
    ActiveRecord::Base.transaction do
      # Update user's plan
      current_user.update!(plan: @target_plan)

      # User keeps their team but billing switches to individual
      # TODO: Handle Stripe subscription migration

      redirect_to user_dashboard_path,
                  notice: "Successfully migrated to #{@target_plan.name} plan!"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to users_subscription_path,
                alert: "Migration failed: #{e.message}"
  end

  def determine_team_plan(user_plan)
    # Map user's team plan to Team model's plan enum
    case user_plan.name
    when /starter/i
      "starter"
    when /pro/i
      "pro"
    else
      "enterprise"
    end
  end
end
