# Base controller for the entire application
# Provides common functionality for authentication, authorization, and security
# All controllers inherit from this class
class ApplicationController < ActionController::Base
  helper NavigationEngine::NavigationHelper
  # Include Pundit for policy-based authorization
  include Pundit::Authorization
  # Include Pagy for efficient pagination
  include Pagy::Backend
  # Include custom activity tracking for audit logs
  include ActivityTracking
  # Include onboarding flow checks for direct users
  include OnboardingCheck

  # Make pagy_url_for available to views
  helper_method :pagy_url_for

  # Set layout dynamically based on user context
  layout :layout_by_resource

  # CSRF Protection - Protect all forms from Cross-Site Request Forgery attacks
  # Uses exception strategy to raise ActionController::InvalidAuthenticityToken
  protect_from_forgery with: :exception

  # Browser compatibility check - block outdated browsers for security
  # Requires support for modern web features (webp, web push, import maps, etc.)
  allow_browser versions: :modern

  # Authentication - require login for all actions by default
  # Controllers can skip this with skip_before_action :authenticate_user!
  before_action :authenticate_user!
  # Check if user account is active (not deactivated/locked)
  # Skip for Devise controllers to allow login/logout
  before_action :check_user_status, unless: :devise_controller?
  # Authorization - ensure all actions are authorized via Pundit policies
  # Skip for index actions and certain controllers
  after_action :verify_authorized, except: [ :index ], unless: :skip_pundit?
  # Ensure index actions use policy scopes for filtering
  after_action :verify_policy_scoped, only: [ :index ], unless: :skip_pundit?

  # Handle authorization failures gracefully
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  # Devise callback - determine where to redirect after successful sign in
  # Checks for stored location first (if user was trying to access a specific page)
  # Falls back to role-based redirect logic
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || redirect_after_sign_in_path
  end

  private

  # Determine appropriate dashboard based on user type and status
  # Complex routing logic for triple-track user system
  def redirect_after_sign_in_path
    if current_user.super_admin?
      # Platform admins go to super admin dashboard
      admin_super_root_path
    elsif current_user.site_admin?
      # Support admins go to site admin dashboard
      admin_site_root_path
    elsif current_user.direct? && !current_user.confirmed?
      # Direct users who haven't confirmed their email need to verify it first
      users_email_verification_path
    elsif current_user.direct? && !current_user.onboarding_completed? && current_user.plan_id.nil?
      # Direct users without a plan need to complete onboarding
      users_onboarding_path
    elsif current_user.direct? && current_user.owns_team? && current_user.team
      # Direct users who own a team go to their team dashboard
      team_root_path(team_slug: current_user.team.slug)
    elsif current_user.direct?
      # Regular direct users go to individual dashboard
      user_dashboard_path
    elsif current_user.invited? && current_user.team
      # Team members go to their team's dashboard
      team_root_path(team_slug: current_user.team.slug)
    elsif current_user.enterprise? && current_user.enterprise_group
      # Enterprise users go to their organization's dashboard
      enterprise_dashboard_path(enterprise_group_slug: current_user.enterprise_group.slug)
    else
      # Fallback to home page
      root_path
    end
  end

  # Handle CSRF token verification failures
  # Called when protect_from_forgery detects invalid/missing CSRF token
  # Logs security events and handles different response formats
  def handle_unverified_request
    # Log CSRF failures for security monitoring
    Rails.logger.warn "[SECURITY] CSRF verification failed for #{request.remote_ip}"
    Rails.logger.warn "[SECURITY] Request: #{request.method} #{request.path}"
    
    # Special handling for Devise sign-in to prevent login loops
    if request.path == '/users/sign_in' && request.post?
      super # Use Rails default handling which resets session but continues
    else
      # Handle different response formats appropriately
      respond_to do |format|
        format.json do
          render json: { error: "CSRF token verification failed. Please refresh and try again." },
                 status: :unprocessable_entity
        end
        format.turbo_stream do
          # Reset session and redirect with Turbo-compatible status
          reset_session
          redirect_to new_user_session_path,
            alert: "Your session has expired. Please sign in again.",
            status: :see_other
        end
        format.html do
          # Standard HTML redirect after session reset
          reset_session
          redirect_to new_user_session_path,
            alert: "Your session has expired. Please sign in again."
        end
      end
    end
  end

  # Check if user account is still active
  # Called on every request to ensure deactivated users can't access the app
  def check_user_status
    if current_user && current_user.status != "active"
      # Force logout for inactive/locked users
      sign_out current_user
      redirect_to new_user_session_path,
        alert: "Your account has been deactivated."
    end
  end

  # Handle Pundit authorization failures
  # Shows friendly error and redirects to safe location
  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    # Try to redirect back, fall back to root if no referrer
    redirect_to(request.referrer || root_path)
  end

  # Determine if Pundit authorization should be skipped
  # Some controllers don't need authorization checks
  def skip_pundit?
    devise_controller? || # Skip for login/logout/registration
    params[:controller] =~ /(^pages$)|(^home$)|(^redirect$)/ || # Skip for public pages
    params[:controller] =~ /^admin\/super\// # Super admin controllers handle their own auth
  end

  # Layout selection based on user type and context
  # Uses different layouts for logged in vs logged out users
  def layout_by_resource
    if devise_controller? || !user_signed_in?
      # Use default layout for auth pages and logged out users
      "application"
    else
      # Use modern sidebar layout for logged in users
      "modern_user"
    end
  end

  # Helper for Pagy pagination to generate URLs with preserved parameters
  # Maintains filter/search params when navigating pages
  def pagy_url_for(pagy, page, absolute: false)
    # Use filter_params if available (from controllers with filtering)
    # Otherwise use all query parameters
    params = if respond_to?(:filter_params, true)
      filter_params.merge(page: page)
    else
      request.query_parameters.merge(page: page)
    end

    # Generate URL with preserved params
    url_for(params.merge(only_path: !absolute))
  end
end
