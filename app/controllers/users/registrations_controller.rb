# Custom registrations controller extending Devise functionality
# Handles both direct user registration and invitation-based registration
# Supports triple-track user system: direct, invited (team), and enterprise users
class Users::RegistrationsController < Devise::RegistrationsController
  # Skip authentication for registration pages (users aren't logged in yet)
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  skip_before_action :check_user_status, only: [ :new, :create ]
  skip_before_action :track_user_activity_async, only: [ :new, :create ]
  
  # Skip Pundit authorization checks for registration
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # Configure permitted parameters for sign up and account update
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]
  # Load invitation if user is registering via invitation link
  before_action :load_invitation, only: [ :new, :create ]
  
  # Use minimal layout for cleaner registration experience
  layout "minimal", only: [:new, :create, :confirmation_sent]

  # GET /resource/sign_up
  # Display registration form
  # Handles both direct registration and invitation-based registration
  def new
    if @invitation
      # For invited users, pre-fill email from invitation
      # They cannot change email and don't need plan selection
      build_resource
      resource.email = @invitation.email
    end

    # Call parent method to render the form
    super
  end

  # POST /resource
  # Handle user registration form submission
  # Complex method that handles three different registration flows:
  # 1. Direct user registration (with email confirmation)
  # 2. Team invitation acceptance
  # 3. Enterprise invitation acceptance
  def create
    if @invitation
      # === INVITATION-BASED REGISTRATION ===
      # Remove params that don't apply to invited users
      filtered_params = sign_up_params.except(:team_name, :plan_id)
      build_resource(filtered_params)

      # Configure user based on invitation
      resource.accepting_invitation = true  # Skip invitation conflict validation
      resource.status = "active"
      resource.email = @invitation.email # Email cannot be changed

      if @invitation.team_invitation?
        # Team member setup
        resource.user_type = "invited"
        resource.team = @invitation.team
        resource.team_role = @invitation.role
      elsif @invitation.enterprise_invitation?
        # Enterprise member setup
        resource.user_type = "enterprise"
        resource.enterprise_group = @invitation.invitable
        resource.enterprise_group_role = @invitation.role
      end

      # Invited users don't need plans (covered by team/enterprise)
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
  # Display confirmation email sent page after direct user registration
  # This page shows a friendly message telling users to check their email
  def confirmation_sent
    # Retrieve email from session (set in after_inactive_sign_up_path_for)
    # We store it in session to prevent users from accessing this page directly
    @email = session.delete(:confirmation_sent_email)
    # Security: If someone tries to access this directly without email, redirect to sign in
    # This prevents information disclosure about registered emails
    redirect_to new_user_session_path unless @email
  end

  protected

  # Configure permitted parameters for sign up
  # This tells Devise which additional parameters to accept beyond email and password
  # Called by before_action on create action
  def configure_sign_up_params
    # Permit additional fields required for registration:
    # - first_name, last_name: User profile information
    # - terms_accepted, privacy_accepted: Legal compliance checkboxes
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :terms_accepted, :privacy_accepted ])
  end

  # Configure permitted parameters for account update
  # This tells Devise which additional parameters to accept when updating account
  # Called by before_action on update action
  def configure_account_update_params
    # Permit name fields for profile updates
    # Note: terms/privacy acceptance can't be changed after registration
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  # The path used after sign up for active (confirmed) accounts
  # Determines where to redirect user after successful registration and sign-in
  # This is only called for users who don't require email confirmation
  def after_sign_up_path_for(resource)
    if resource.direct? && resource.owns_team? && resource.team
      # Direct users who own a team go to their team dashboard
      # This happens after onboarding when they've created a team
      team_root_path(team_slug: resource.team.slug)
    elsif resource.direct?
      # Direct users without teams go to individual dashboard
      user_dashboard_path
    elsif resource.invited? && resource.team
      # Team members go to their team's dashboard
      team_root_path(team_slug: resource.team.slug)
    elsif resource.enterprise? && resource.enterprise_group
      # Enterprise users go to their organization's dashboard
      enterprise_dashboard_path(enterprise_group_slug: resource.enterprise_group.slug)
    else
      # Fallback to home page (shouldn't normally happen)
      root_path
    end
  end

  # The path used after sign up for inactive accounts
  # Called when user needs email confirmation (direct users)
  # Inactive means the account exists but can't sign in yet
  def after_inactive_sign_up_path_for(resource)
    # Store the email in session for the confirmation_sent page
    # This allows us to show personalized message without URL parameters
    session[:confirmation_sent_email] = resource.email
    # Redirect to our custom confirmation sent page
    confirmation_sent_users_registrations_path
  end

  private

  # Load invitation from token if user is registering via invitation
  # Called by before_action for new and create actions
  # Handles both URL parameter and session-stored tokens
  def load_invitation
    # Check both params and session for invitation token
    # Params: when user clicks invitation link
    # Session: when form is re-rendered after validation error
    token = params[:invitation_token] || session[:invitation_token]
    if token.present?
      # Find invitation by secure token
      @invitation = Invitation.find_by(token: token)
      # Validate invitation is still valid
      if @invitation && !@invitation.accepted? && !@invitation.expired?
        # Store token in session to persist across form submissions
        session[:invitation_token] = token
      else
        # Invalid/expired/already used invitation - clear everything
        @invitation = nil
        session.delete(:invitation_token)
      end
    end
  end

end
