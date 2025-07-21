class Users::OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_direct_user
  before_action :ensure_onboarding_not_completed, except: [:complete]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  
  layout "minimal"
  
  # GET /users/onboarding
  def show
    @step = current_user.onboarding_step || 'welcome'
    
    case @step
    when 'welcome'
      render :welcome
    when 'plan_selection'
      prepare_plan_selection
      render :plan_selection
    else
      redirect_to plan_selection_users_onboarding_path
    end
  end
  
  # GET /users/onboarding/plan_selection
  def plan_selection
    prepare_plan_selection
    current_user.update(onboarding_step: 'plan_selection')
  end
  
  # POST /users/onboarding/plan_selection
  def update_plan
    @plan = Plan.find_by(id: params[:plan_id])
    
    if @plan.nil? || !@plan.active? || @plan.contact_sales?
      flash[:alert] = "Please select a valid plan"
      redirect_to plan_selection_users_onboarding_path and return
    end
    
    # Handle team plan creation
    if @plan.plan_segment == 'team'
      if params[:team_name].blank?
        flash[:alert] = "Team name is required for team plans"
        redirect_to plan_selection_users_onboarding_path and return
      end
      
      # Create team for the user
      team = create_team_for_user(current_user, params[:team_name], @plan)
      
      if team.nil?
        flash[:alert] = "Failed to create team. Please try again."
        redirect_to plan_selection_users_onboarding_path and return
      end
    else
      # Individual plan - just assign to user
      current_user.plan = @plan
    end
    
    # Mark onboarding as complete
    current_user.onboarding_completed = true
    current_user.onboarding_step = 'completed'
    
    if current_user.save
      flash[:notice] = "Welcome! Your plan has been set up successfully."
      redirect_to after_onboarding_path
    else
      flash[:alert] = "There was an error setting up your plan. Please try again."
      redirect_to plan_selection_users_onboarding_path
    end
  end
  
  # GET /users/onboarding/complete
  def complete
    if current_user.onboarding_completed?
      redirect_to after_onboarding_path
    else
      redirect_to users_onboarding_path
    end
  end
  
  private
  
  def ensure_direct_user
    unless current_user.direct?
      flash[:alert] = "Onboarding is only available for direct users"
      redirect_to root_path
    end
  end
  
  def ensure_onboarding_not_completed
    if current_user.onboarding_completed?
      redirect_to after_onboarding_path
    end
  end
  
  def prepare_plan_selection
    @available_plans = Plan.available_for_signup
                          .order(:plan_segment, :amount_cents)
  end
  
  def after_onboarding_path
    if current_user.owns_team? && current_user.team
      team_root_path(team_slug: current_user.team.slug)
    else
      user_dashboard_path
    end
  end
  
  def create_team_for_user(user, team_name, plan)
    team = Team.create(
      name: team_name,
      admin: user,
      created_by: user,
      plan: "starter", # Default team plan type
      status: "active",
      max_members: plan.max_team_members || 5
    )
    
    if team.persisted?
      # Update user to reflect team ownership
      user.update!(
        team: team,
        team_role: "admin",
        owns_team: true,
        plan: plan
      )
      team
    else
      Rails.logger.error "Failed to create team for user #{user.id}: #{team.errors.full_messages.join(', ')}"
      nil
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create team for user #{user.id}: #{e.message}"
    nil
  end
end