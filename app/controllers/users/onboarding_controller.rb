# Controller for handling new direct user onboarding flow
# Guides users through plan selection after email verification
# Supports both individual and team plan creation
class Users::OnboardingController < ApplicationController
  # Ensure user is logged in
  before_action :authenticate_user!
  # Only direct users go through onboarding (invited/enterprise have plans via their org)
  before_action :ensure_direct_user
  # Prevent accessing onboarding if already completed (except complete action)
  before_action :ensure_onboarding_not_completed, except: [:complete]
  # Skip Pundit - these are personal user actions
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  
  # Use minimal layout for focused onboarding experience
  layout "minimal"
  
  # GET /users/onboarding
  # Display current onboarding step based on user progress
  # Steps: welcome -> plan_selection -> completed
  def show
    # Get current step from user record (defaults to welcome)
    @step = current_user.onboarding_step || 'welcome'
    
    case @step
    when 'welcome'
      # Show welcome screen
      render :welcome
    when 'plan_selection'
      # Show plan selection with available plans
      prepare_plan_selection
      render :plan_selection
    else
      # Unknown step - redirect to plan selection
      redirect_to plan_selection_users_onboarding_path
    end
  end
  
  # GET /users/onboarding/plan_selection
  # Display plan selection page with individual and team options
  def plan_selection
    # Load available plans for display
    prepare_plan_selection
    # Update user's onboarding progress
    current_user.update(onboarding_step: 'plan_selection')
  end
  
  # POST /users/onboarding/plan_selection
  # Process plan selection and complete onboarding
  # Creates team if team plan selected
  def update_plan
    # Find selected plan
    @plan = Plan.find_by(id: params[:plan_id])
    
    # Validate plan selection
    if @plan.nil? || !@plan.active? || @plan.contact_sales?
      flash[:alert] = "Please select a valid plan"
      redirect_to plan_selection_users_onboarding_path and return
    end
    
    # Handle team plan creation
    if @plan.plan_segment == 'team'
      # Team plans require a team name
      if params[:team_name].blank?
        flash[:alert] = "Team name is required for team plans"
        redirect_to plan_selection_users_onboarding_path and return
      end
      
      # Create team for the user (user becomes team admin)
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
  # Completion check endpoint - redirects based on onboarding status
  def complete
    if current_user.onboarding_completed?
      # Onboarding done - go to appropriate dashboard
      redirect_to after_onboarding_path
    else
      # Not done - send back to onboarding
      redirect_to users_onboarding_path
    end
  end
  
  private
  
  # Ensure only direct users can access onboarding
  # Invited and enterprise users get plans through their organizations
  def ensure_direct_user
    unless current_user.direct?
      flash[:alert] = "Onboarding is only available for direct users"
      redirect_to root_path
    end
  end
  
  # Prevent accessing onboarding flow if already completed
  # Ensures users can't re-select plans or re-do onboarding
  def ensure_onboarding_not_completed
    if current_user.onboarding_completed?
      redirect_to after_onboarding_path
    end
  end
  
  # Load available plans for selection page
  # Filters to only show active, non-contact-sales plans
  def prepare_plan_selection
    @available_plans = Plan.available_for_signup
                          .order(:plan_segment, :amount_cents)
  end
  
  # Determine where to send user after completing onboarding
  # Team owners go to team dashboard, others to individual dashboard
  def after_onboarding_path
    if current_user.owns_team? && current_user.team
      # User created a team - go to team dashboard
      team_root_path(team_slug: current_user.team.slug)
    else
      # Individual plan - go to user dashboard
      user_dashboard_path
    end
  end
  
  # Create a new team when user selects a team plan
  # Sets up user as team admin and owner
  def create_team_for_user(user, team_name, plan)
    # Create team with user as admin
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
      # User becomes team admin and owner
      user.update!(
        team: team,
        team_role: "admin",
        owns_team: true,
        plan: plan
      )
      team
    else
      # Log error for debugging
      Rails.logger.error "Failed to create team for user #{user.id}: #{team.errors.full_messages.join(', ')}"
      nil
    end
  rescue ActiveRecord::RecordInvalid => e
    # Handle validation errors
    Rails.logger.error "Failed to create team for user #{user.id}: #{e.message}"
    nil
  end
end