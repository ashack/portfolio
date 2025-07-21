class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  skip_before_action :check_user_status, only: [ :new, :create ]
  skip_before_action :track_user_activity_async, only: [ :new, :create ]
  
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]
  before_action :load_invitation, only: [ :new, :create ]
  
  layout "minimal", only: [:new, :create, :confirmation_sent]

  # GET /resource/sign_up
  def new
    if @invitation
      # For invited users, we don't need plan selection
      build_resource
      resource.email = @invitation.email
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
      build_resource(sign_up_params)

      # Set user type
      resource.user_type = "direct"
      resource.status = "active"

      # Skip plan assignment for direct users - they'll select during onboarding
      # Plan selection is now handled in the onboarding flow after email verification
      resource.plan_id = nil
      resource.onboarding_completed = false
      resource.onboarding_step = 'welcome'

      resource.save

      # Team creation is now handled in onboarding flow after plan selection

      yield resource if block_given?

      if resource.persisted?
        # For direct users who haven't confirmed their email, don't sign them in
        if resource.direct? && !resource.confirmed?
          set_flash_message! :notice, :signed_up_but_unconfirmed
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        elsif resource.active_for_authentication?
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
    end
  end

  # GET /users/registrations/confirmation_sent
  def confirmation_sent
    @email = session.delete(:confirmation_sent_email)
    # If someone tries to access this directly without email, redirect to sign in
    redirect_to new_user_session_path unless @email
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
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
    # Store the email in session for the confirmation_sent page
    session[:confirmation_sent_email] = resource.email
    confirmation_sent_users_registrations_path
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

end
