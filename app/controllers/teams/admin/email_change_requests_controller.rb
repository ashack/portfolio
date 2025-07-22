# Teams::Admin::EmailChangeRequestsController - Team member email change approval
#
# PURPOSE:
# - Manages email change requests for team members
# - Implements secure email change approval workflow
# - Provides team admin oversight for email modifications
# - Prevents unauthorized email changes that could compromise security
#
# ACCESS LEVEL: Team Admin Only
# - Team admins can approve/reject email changes for their team members
# - Email change requests require administrative approval for security
# - Both team owners and invited admins can manage email changes
# - Team members can request but cannot directly change emails
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/admin/email_change_requests (index)
# - GET /teams/:team_slug/admin/email_change_requests/:token (show)
# - GET /teams/:team_slug/admin/email_change_requests/new (new)
# - POST /teams/:team_slug/admin/email_change_requests (create)
# - PATCH /teams/:team_slug/admin/email_change_requests/:token/approve (approve)
# - PATCH /teams/:team_slug/admin/email_change_requests/:token/reject (reject)
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS: Can request email changes, need admin approval
# - DIRECT USERS (team owners): Can approve email changes for team members
# - ENTERPRISE USERS: Cannot access (separate enterprise email management)
#
# EMAIL CHANGE SECURITY:
# - Two-step approval process prevents unauthorized email changes
# - Token-based request system for secure identification
# - Audit trail with approval/rejection reasons
# - Time-limited requests (configurable expiration)
# - Team admin oversight prevents social engineering attacks
#
# WORKFLOW PROCESS:
# 1. Team member requests email change (via profile controller)
# 2. Request created with unique token and pending status
# 3. Team admin reviews request and provides approval/rejection
# 4. Approved requests trigger actual email change
# 5. All actions logged for security audit
#
# SECURITY CONSIDERATIONS:
# - Token-based access prevents direct manipulation
# - Team-scoped requests (no cross-team access)
# - Pundit authorization for all sensitive operations
# - Mandatory rejection reasons for audit compliance
# - Email validation prevents invalid email addresses
# - Approval process logged for security monitoring
#
class Teams::Admin::EmailChangeRequestsController < Teams::Admin::BaseController
  include Pundit::Authorization
  before_action :set_email_change_request, only: [ :show, :approve, :reject ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # EMAIL CHANGE REQUEST LIST
  # Shows all pending and processed email change requests for team members
  # Team admins can only see requests from their own team
  def index
    # Team admins can only see requests from their team members
    # Policy scope ensures team isolation and proper authorization
    @email_change_requests = policy_scope(EmailChangeRequest).includes(:user, :approved_by)
                                                            .recent
    @pagy, @email_change_requests = pagy(@email_change_requests)
  end

  # EMAIL CHANGE REQUEST DETAILS
  # Shows detailed information about a specific email change request
  # Includes original email, requested email, reason, and approval status
  def show
    authorize @email_change_request, :show?
  end

  # NEW EMAIL CHANGE REQUEST FORM
  # Allows team members to request email changes through admin interface
  # Alternative to profile-based email change requests
  def new
    @email_change_request = EmailChangeRequest.new
    authorize @email_change_request, :create?
  end

  # CREATE EMAIL CHANGE REQUEST
  # Processes new email change requests with validation and security checks
  # Associates request with current user and team context
  def create
    @email_change_request = EmailChangeRequest.new(email_change_request_params)
    @email_change_request.user = current_user
    authorize @email_change_request, :create?

    if @email_change_request.save
      redirect_to team_admin_email_change_requests_path(@team),
                  notice: "Email change request submitted successfully. You will be notified when it's reviewed."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # APPROVE EMAIL CHANGE REQUEST
  # Approves pending email change requests and triggers actual email change
  # Includes optional approval notes for audit trail
  def approve
    authorize @email_change_request, :approve?

    if @email_change_request.approve!(current_user, notes: params[:notes])
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  notice: "Email change request approved successfully."
    else
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  alert: "Failed to approve email change request: #{@email_change_request.errors.full_messages.join(', ')}"
    end
  end

  # REJECT EMAIL CHANGE REQUEST
  # Rejects email change requests with mandatory rejection reason
  # Rejection reasons required for audit compliance and user feedback
  def reject
    authorize @email_change_request, :reject?

    # Rejection reason is mandatory for audit compliance
    if params[:notes].blank?
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  alert: "Rejection reason is required."
      return
    end

    if @email_change_request.reject!(current_user, notes: params[:notes])
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  notice: "Email change request rejected."
    else
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  alert: "Failed to reject email change request: #{@email_change_request.errors.full_messages.join(', ')}"
    end
  end

  private

  # EMAIL CHANGE REQUEST LOOKUP
  # Securely loads email change requests by token with team scope verification
  # Prevents access to email change requests from other teams
  def set_email_change_request
    @email_change_request = EmailChangeRequest.joins(:user)
                                             .where(users: { team_id: current_user.team_id })
                                             .find_by!(token: params[:token])
  end

  # EMAIL CHANGE REQUEST PARAMETERS
  # Filters allowed parameters for email change requests
  # Includes new email address and reason for change
  def email_change_request_params
    params.require(:email_change_request).permit(:new_email, :reason)
  end
end
