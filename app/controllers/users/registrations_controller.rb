class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  skip_before_action :check_user_status, only: [ :new, :create ]
  skip_before_action :track_user_activity, only: [ :new, :create ]
  skip_after_action :verify_authorized, only: [ :new, :create ]
  skip_after_action :verify_policy_scoped, only: [ :new, :create ]

  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]
  before_action :set_available_plans, only: [ :new, :create ]
  before_action :load_invitation, only: [ :new, :create ]

  # GET /resource/sign_up
  def new
    if @invitation
      # For invited users, we don't need plan selection
      build_resource
      resource.email = @invitation.email
    else
      # Check if user selected a plan segment
      @plan_segment = params[:plan_segment] || session[:plan_segment] || "individual"

      # Store in session for form resubmission
      session[:plan_segment] = @plan_segment
    end

    super
  end

  # POST /resource
  def create
    if @invitation
      # Handle invited user registration
      filtered_params = sign_up_params.except(:team_name, :plan_id)
      build_resource(filtered_params)

      # Set invited user attributes based on invitation type
      resource.accepting_invitation = true  # Skip invitation conflict validation
      resource.status = "active"
      resource.email = @invitation.email

      if @invitation.team_invitation?
        # Handle team invitation
        resource.user_type = "invited"
        resource.team = @invitation.team
        resource.team_role = @invitation.role
      elsif @invitation.enterprise_invitation?
        # Handle enterprise invitation
        resource.user_type = "enterprise"
        resource.enterprise_group = @invitation.invitable
        resource.enterprise_group_role = @invitation.role
      end

      # No plan needed for invited/enterprise users
      resource.plan_id = nil

      # Skip email confirmation for invited users (they already received an invitation)
      resource.skip_confirmation!

      if resource.save
        # Mark invitation as accepted
        if @invitation
          Rails.logger.info "Attempting to mark invitation #{@invitation.id} (#{@invitation.email}) as accepted"
          Rails.logger.info "Invitation type: #{@invitation.invitation_type}, before update: accepted_at=#{@invitation.accepted_at}"

          @invitation.update_column(:accepted_at, Time.current)
          @invitation.reload

          Rails.logger.info "Invitation after update: accepted_at=#{@invitation.accepted_at}, accepted?=#{@invitation.accepted?}"

          # Update enterprise group admin if this is an enterprise admin invitation
          if @invitation.enterprise_invitation? && @invitation.admin? && @invitation.invitable
            Rails.logger.info "Updating enterprise group admin to user #{resource.id}"
            @invitation.invitable.update!(admin: resource)
          end
        else
          Rails.logger.error "No @invitation found when trying to mark as accepted!"
        end

        # Clean up session
        session.delete(:invitation_token)

        yield resource if block_given?

        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    else
      # Handle direct user registration
      @plan_segment = params[:user][:plan_segment] || session[:plan_segment] || "individual"

      # Store team_name separately before filtering params
      team_name = params[:user][:team_name]

      # Filter out team_name from sign_up_params to avoid UnknownAttributeError
      filtered_params = sign_up_params.except(:team_name)
      build_resource(filtered_params)

      # Set user type
      resource.user_type = "direct"
      resource.status = "active"

      # Handle plan assignment based on segment
      if params[:user][:plan_id].present?
        plan = Plan.find_by(id: params[:user][:plan_id])

        if plan && plan.active? && !plan.contact_sales?
          resource.plan_id = plan.id

          # If selecting a team plan, validate team name
          if plan.plan_segment == "team"
            if team_name.blank?
              resource.errors.add(:base, "Team name is required when selecting a team plan")
              set_minimum_password_length
              set_available_plans
              render :new, status: :unprocessable_entity and return
            end
          end
        else
          resource.errors.add(:plan, "must be a valid plan")
          set_minimum_password_length
          set_available_plans
          render :new, status: :unprocessable_entity and return
        end
      else
        # If no plan selected, assign the free individual plan
        free_plan = Plan.find_by(plan_segment: "individual", amount_cents: 0, active: true)
        resource.plan_id = free_plan.id if free_plan
      end

      resource.save

      # Create team if user selected a team plan
      if resource.persisted? && resource.plan&.plan_segment == "team"
        create_team_for_user(resource, team_name)
      end

      yield resource if block_given?

      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        set_available_plans
        respond_with resource
      end
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :plan_id, :team_name ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    if resource.direct? && resource.owns_team? && resource.team
      # Direct users who own a team go to their team dashboard
      team_root_path(team_slug: resource.team.slug)
    elsif resource.direct?
      user_dashboard_path
    elsif resource.invited? && resource.team
      team_root_path(team_slug: resource.team.slug)
    elsif resource.enterprise? && resource.enterprise_group
      enterprise_dashboard_path(enterprise_group_slug: resource.enterprise_group.slug)
    else
      root_path
    end
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  private

  def load_invitation
    token = params[:invitation_token] || session[:invitation_token]
    if token.present?
      @invitation = Invitation.find_by(token: token)
      if @invitation && !@invitation.accepted? && !@invitation.expired?
        session[:invitation_token] = token
      else
        @invitation = nil
        session.delete(:invitation_token)
      end
    end
  end

  def set_available_plans
    @plan_segment ||= params[:plan_segment] || session[:plan_segment] || "individual"

    # Show all available plans (both individual and team) for direct registration
    # Users can choose between individual or team plans
    @available_plans = Plan.available_for_signup
                          .order(:plan_segment, :amount_cents)
  end

  def create_team_for_user(user, team_name)
    team = Team.create!(
      name: team_name,
      admin: user,
      created_by: user,
      plan: "starter",
      status: "active",
      max_members: user.plan.max_team_members || 5
    )

    # Update user to reflect team ownership
    user.update!(
      team: team,
      team_role: "admin",
      owns_team: true
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create team for user #{user.id}: #{e.message}"
  end
end
