# Users::PlanMigrationsController
#
# PURPOSE: Handles complex plan migrations between different plan segments (individual <-> team)
# for direct users in the triple-track SaaS system. This controller manages the intricate
# business logic of migrating users between fundamentally different billing structures.
#
# SCOPE: Direct users only - part of the triple-track system where:
# - Direct users: Individual registrations with personal billing
# - Invited users: Team members (cannot migrate plans)
# - Enterprise users: Large organization members (cannot migrate plans)
#
# FUNCTIONALITY:
# - Handles migrations between individual and team plan segments
# - Creates teams automatically when migrating to team plans
# - Manages complex subscription transitions (Stripe integration pending)
# - Maintains data integrity during cross-segment migrations
# - Prevents invalid migration attempts (same segment, unauthorized users)
#
# SECURITY: Pundit authorization ensures only authorized direct users can perform migrations
#
class Users::PlanMigrationsController < ApplicationController
  # Ensure user is authenticated before any plan migration operations
  before_action :authenticate_user!

  # Critical: Only direct users can migrate between plan segments
  # Invited/enterprise users have fixed billing through their parent organization
  before_action :ensure_direct_user

  # Load current plan for comparison and validation
  before_action :set_current_plan

  # GET /users/plan_migrations/new?plan_id=X
  # Display plan migration confirmation form with migration requirements
  # Shows different UI based on migration type (individual->team vs team->individual)
  def new
    @target_plan = Plan.find(params[:plan_id])
    # Authorize using Pundit policy for plan migration operations
    authorize :plan_migration, :create?

    # Prevent migrations within the same plan segment - use regular subscription changes instead
    if @target_plan.plan_segment == @current_plan&.plan_segment
      redirect_to users_subscription_path, alert: "Please use the regular plan change for same type plans."
      return
    end

    # Determine if team creation is required for this migration
    # Users migrating to team plans who don't already own a team need to create one
    @requires_team_creation = @target_plan.plan_segment == "team" && !current_user.owns_team?
  end

  # POST /users/plan_migrations
  # Execute the plan migration based on target plan segment
  # Handles complex business logic for cross-segment migrations
  def create
    @target_plan = Plan.find(params[:plan_id])
    # Re-authorize on execution to prevent CSRF/timing attacks
    authorize :plan_migration, :create?

    # Route to appropriate migration method based on target plan type
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

  # SECURITY: Enforce direct user restriction for plan migrations
  # Only direct users can migrate between plan segments since they control their own billing
  # Invited users belong to teams/enterprises and cannot change billing independently
  def ensure_direct_user
    unless current_user.direct?
      redirect_to user_dashboard_path, alert: "Only direct users can migrate plans."
    end
  end

  # Load the user's current plan for migration comparison and validation
  def set_current_plan
    @current_plan = current_user.plan
  end

  # COMPLEX BUSINESS LOGIC: Individual -> Team Plan Migration
  # This migration involves creating a team structure and updating billing model
  # The user becomes a team admin while maintaining their direct user status
  def migrate_to_team_plan
    team_name = params[:team_name]

    # Validate required team name for team creation
    if team_name.blank?
      redirect_to new_users_plan_migration_path(plan_id: @target_plan.id),
                  alert: "Team name is required when migrating to a team plan."
      return
    end

    # Use database transaction to ensure atomic operation
    # Critical: If any step fails, the entire migration must be rolled back
    ActiveRecord::Base.transaction do
      # Create team structure if user doesn't already own one
      # Direct users can own teams while maintaining individual billing control
      unless current_user.owns_team?
        team = Team.create!(
          name: team_name,
          admin: current_user,                      # User becomes team admin
          created_by: current_user,
          plan: determine_team_plan(@target_plan),  # Map user plan to team plan enum
          status: "active",
          max_members: @target_plan.max_team_members || 5
        )

        # Update user relationships to reflect team ownership
        current_user.update!(
          team: team,
          team_role: "admin",
          owns_team: true  # Critical: Maintains direct user privileges
        )
      end

      # Update user's billing plan to the new team-segment plan
      current_user.update!(plan: @target_plan)

      # TODO: Handle Stripe subscription migration from individual to team billing
      # This will require:
      # 1. Canceling current individual subscription
      # 2. Creating new team subscription with proper pricing
      # 3. Handling prorated billing adjustments
      # 4. Updating payment methods if needed

      redirect_to user_dashboard_path,
                  notice: "Successfully migrated to #{@target_plan.name} plan with your team!"
    end
  rescue ActiveRecord::RecordInvalid => e
    # Handle any validation failures during the complex migration process
    redirect_to new_users_plan_migration_path(plan_id: @target_plan.id),
                alert: "Migration failed: #{e.message}"
  end

  # BUSINESS LOGIC: Team -> Individual Plan Migration
  # Simpler migration that switches billing model while preserving team ownership
  # User keeps their team but billing becomes individual-focused
  def migrate_to_individual_plan
    # Use database transaction for consistency
    ActiveRecord::Base.transaction do
      # Update user's plan to individual segment
      current_user.update!(plan: @target_plan)

      # IMPORTANT: User keeps their team ownership and relationships
      # Only the billing model changes from team-based to individual-based
      # This allows team owners to have individual features while maintaining teams

      # TODO: Handle Stripe subscription migration from team to individual billing
      # This requires careful handling to avoid double-billing scenarios

      redirect_to user_dashboard_path,
                  notice: "Successfully migrated to #{@target_plan.name} plan!"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to users_subscription_path,
                alert: "Migration failed: #{e.message}"
  end

  # UTILITY: Map user plan to team model's plan enum
  # The Plan model uses different naming than the Team model's plan enum
  # This method provides the translation layer between the two systems
  def determine_team_plan(user_plan)
    # Map user's team plan to Team model's plan enum values
    case user_plan.name
    when /starter/i
      "starter"    # Team.plan = "starter"
    when /pro/i
      "pro"        # Team.plan = "pro"
    else
      "enterprise" # Team.plan = "enterprise"
    end
  end
end
