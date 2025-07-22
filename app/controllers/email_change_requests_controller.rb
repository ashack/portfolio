# Controller for managing email change requests
# Provides secure email change workflow with admin approval
# Includes activity tracking and proper authorization checks
class EmailChangeRequestsController < ApplicationController
  # Include activity tracking for audit logs
  include ActivityTrackable
  # Include Pundit for authorization (redundant but explicit)
  include Pundit::Authorization

  # Require authentication for all actions
  before_action :authenticate_user!
  # Load email change request by secure token for show action
  before_action :set_email_change_request, only: [ :show ]
  # Set team context for invited users' layout
  before_action :set_team_for_layout
  # Ensure all actions are authorized except index
  after_action :verify_authorized, except: :index
  # Ensure index action uses policy scope for proper filtering
  after_action :verify_policy_scoped, only: :index

  # GET /email_change_requests
  # List user's email change requests (scoped by policy)
  # Shows request history and current status
  def index
    # Use policy scope to ensure users only see their own requests
    # (or all requests for admins)
    @email_change_requests = policy_scope(EmailChangeRequest).recent
    # Paginate results for better performance
    @pagy, @email_change_requests = pagy(@email_change_requests)
  end

  # GET /email_change_requests/new
  # Display form to request email change
  # Prevents multiple pending requests per user
  def new
    # Build new request for current user
    @email_change_request = current_user.email_change_requests.build
    # Ensure user is authorized to create email change requests
    authorize @email_change_request

    # Prevent multiple pending requests - security and UX consideration
    if current_user.email_change_requests.pending.exists?
      redirect_to email_change_requests_path, alert: "You already have a pending email change request."
      return
    end

    # Set appropriate cancel path based on user type
    @cancel_path = profile_path_for_user_type
  end

  # POST /email_change_requests
  # Submit email change request for admin review
  # Includes activity tracking and automatic notifications
  def create
    # Build request with permitted parameters
    @email_change_request = current_user.email_change_requests.build(email_change_request_params)
    # Ensure user is authorized to create requests
    authorize @email_change_request

    if @email_change_request.save
      # Track the request in audit logs for security monitoring
      # This creates a permanent record of the email change attempt
      track_user_action("email_change_requested", current_user, {
        new_email: @email_change_request.new_email,
        reason: @email_change_request.reason
      })

      # Redirect with success message
      # Note: Notification to admins sent automatically via after_create callback
      redirect_to @email_change_request, notice: "Email change request submitted successfully. You will be notified when it's reviewed."
    else
      # Re-render form with validation errors
      @cancel_path = profile_path_for_user_type
      render :new, status: :unprocessable_entity
    end
  end

  # GET /email_change_requests/:token
  # Display email change request details and status
  # Uses secure token instead of ID for privacy
  def show
    # Ensure user can view this specific request
    authorize @email_change_request
    # Render request details view
  end

  private

  # Load email change request by secure token
  # Uses token instead of ID for privacy and security
  def set_email_change_request
    @email_change_request = EmailChangeRequest.find_by!(token: params[:token])
  end

  # Strong parameters for email change request form
  # Only allows new_email and reason fields
  def email_change_request_params
    params.require(:email_change_request).permit(:new_email, :reason)
  end

  # Determine appropriate profile/cancel path based on user type
  # Part of the triple-track user system navigation logic
  def profile_path_for_user_type
    # Check admin status first (system roles take precedence)
    if current_user.super_admin? || current_user.site_admin?
      admin_site_profile_path
    elsif current_user.user_type == "direct"
      # Direct users have individual dashboards
      user_dashboard_path
    elsif current_user.user_type == "invited"
      # Team members don't have individual profiles, redirect to team dashboard
      team_root_path(team_slug: current_user.team.slug)
    else
      # Fallback to home page
      root_path
    end
  end

  # Set team context for layout rendering
  # Used by invited users who need team-specific navigation
  def set_team_for_layout
    @team = current_user.team if current_user&.invited?
  end
end
