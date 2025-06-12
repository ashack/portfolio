class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :check_user_status
  before_action :track_user_activity
  after_action :verify_authorized, except: [ :index ], unless: :skip_pundit?
  after_action :verify_policy_scoped, only: [ :index ], unless: :skip_pundit?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

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
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end
end
