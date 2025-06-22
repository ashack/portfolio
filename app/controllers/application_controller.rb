class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  include ActivityTracking

  helper_method :pagy_url_for

  # CSRF Protection - Protect all forms from Cross-Site Request Forgery
  protect_from_forgery with: :exception

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :check_user_status, unless: :devise_controller?
  after_action :verify_authorized, except: [ :index ], unless: :skip_pundit?
  after_action :verify_policy_scoped, only: [ :index ], unless: :skip_pundit?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  # Devise redirect after sign in
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || redirect_after_sign_in_path
  end

  private

  def redirect_after_sign_in_path
    if current_user.super_admin?
      admin_super_root_path
    elsif current_user.site_admin?
      admin_site_root_path
    elsif current_user.direct? && current_user.owns_team? && current_user.team
      # Direct users who own a team go to their team dashboard
      team_root_path(team_slug: current_user.team.slug)
    elsif current_user.direct?
      user_dashboard_path
    elsif current_user.invited? && current_user.team
      team_root_path(team_slug: current_user.team.slug)
    elsif current_user.enterprise? && current_user.enterprise_group
      enterprise_dashboard_path(enterprise_group_slug: current_user.enterprise_group.slug)
    else
      root_path
    end
  end

  # Handle CSRF token verification failures
  def handle_unverified_request
    # Log CSRF failures for security monitoring
    Rails.logger.warn "[SECURITY] CSRF verification failed for #{request.remote_ip}"
    Rails.logger.warn "[SECURITY] Request: #{request.method} #{request.path}"

    respond_to do |format|
      format.json do
        render json: { error: "CSRF token verification failed. Please refresh and try again." },
               status: :unprocessable_entity
      end
      format.turbo_stream do
        reset_session
        redirect_to new_user_session_path,
          alert: "Your session has expired. Please sign in again.",
          status: :see_other
      end
      format.html do
        reset_session
        redirect_to new_user_session_path,
          alert: "Your session has expired. Please sign in again."
      end
    end
  end

  def check_user_status
    if current_user && current_user.status != "active"
      sign_out current_user
      redirect_to new_user_session_path,
        alert: "Your account has been deactivated."
    end
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^pages$)|(^home$)|(^redirect$)/
  end

  # Helper for Pagy to generate URLs with preserved parameters
  def pagy_url_for(pagy, page, absolute: false)
    params = if respond_to?(:filter_params, true)
      filter_params.merge(page: page)
    else
      request.query_parameters.merge(page: page)
    end

    url_for(params.merge(only_path: !absolute))
  end
end
