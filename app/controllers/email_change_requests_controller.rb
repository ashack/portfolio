class EmailChangeRequestsController < ApplicationController
  include ActivityTrackable
  include Pundit::Authorization

  layout :determine_layout

  before_action :authenticate_user!
  before_action :set_email_change_request, only: [ :show ]
  before_action :set_team_for_layout
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @email_change_requests = policy_scope(EmailChangeRequest).recent
    @pagy, @email_change_requests = pagy(@email_change_requests)
  end

  def new
    @email_change_request = current_user.email_change_requests.build
    authorize @email_change_request

    # Check if user already has a pending request
    if current_user.email_change_requests.pending.exists?
      redirect_to email_change_requests_path, alert: "You already have a pending email change request."
      return
    end

    @cancel_path = profile_path_for_user_type
  end

  def create
    @email_change_request = current_user.email_change_requests.build(email_change_request_params)
    authorize @email_change_request

    if @email_change_request.save
      # Log the request (notification sent automatically after_create)
      track_user_action("email_change_requested", current_user, {
        new_email: @email_change_request.new_email,
        reason: @email_change_request.reason
      })

      redirect_to @email_change_request, notice: "Email change request submitted successfully. You will be notified when it's reviewed."
    else
      @cancel_path = profile_path_for_user_type
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @email_change_request
  end

  private

  def set_email_change_request
    @email_change_request = EmailChangeRequest.find_by!(token: params[:token])
  end

  def email_change_request_params
    params.require(:email_change_request).permit(:new_email, :reason)
  end

  def profile_path_for_user_type
    # Check admin status first (system_role)
    if current_user.super_admin? || current_user.site_admin?
      admin_site_profile_path
    elsif current_user.user_type == "direct"
      user_dashboard_path
    elsif current_user.user_type == "invited"
      # Team members don't have individual profiles, redirect to team dashboard
      team_root_path(team_slug: current_user.team.slug)
    else
      root_path
    end
  end

  def determine_layout
    return "application" unless user_signed_in?

    # Check admin status first (system_role)
    if current_user.super_admin? || current_user.site_admin?
      Rails.logger.debug "EMAIL_CHANGE_REQUEST: Using admin layout for user #{current_user.email} (#{current_user.system_role})"
      "admin"
    elsif current_user.user_type == "invited"
      Rails.logger.debug "EMAIL_CHANGE_REQUEST: Using team layout for user #{current_user.email}"
      "team"
    else
      Rails.logger.debug "EMAIL_CHANGE_REQUEST: Using application layout for user #{current_user.email}"
      "application"
    end
  end

  def set_team_for_layout
    @team = current_user.team if current_user&.invited?
  end
end
