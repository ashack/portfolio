class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  # CSRF Protection - Protect all forms from Cross-Site Request Forgery
  protect_from_forgery with: :exception

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :check_user_status, unless: :devise_controller?
  before_action :track_user_activity
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
      enterprise_group_root_path(enterprise_group_slug: current_user.enterprise_group.slug)
    else
      root_path
    end
  end

  # Additional CSRF protection helper for AJAX requests
  def verify_csrf_token_for_ajax
    return true unless request.xhr?

    unless verified_request?
      respond_to do |format|
        format.json { render json: { error: "CSRF token verification failed" }, status: :forbidden }
        format.html { redirect_to root_path, alert: "Security token verification failed" }
      end
      return false
    end
    true
  end

  def check_user_status
    if current_user && current_user.status != "active"
      sign_out current_user
      redirect_to new_user_session_path,
        alert: "Your account has been deactivated."
    end
  end

  def track_user_activity
    if current_user
      current_user.update_column(:last_activity_at, Time.current)
    end
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^pages$)|(^home$)|(^redirect$)/
  end
end
