# Super Admin Email Change Requests Controller
#
# PURPOSE:
# Manages the approval workflow for user email change requests across the platform.
# Super admins review and approve/reject email changes for security and audit compliance.
#
# ACCESS RESTRICTIONS:
# - Only super admins can approve/reject email changes
# - Full access to all email change requests platform-wide
# - Can see sensitive user identification information
# - Inherits from Admin::Super::BaseController which enforces super_admin role
#
# BUSINESS RULES:
# - Email changes require super admin approval for security
# - Approval/rejection must include notes for audit trail
# - Email change requests have expiration dates
# - Users notified of approval/rejection decisions
#
# SECURITY CONSIDERATIONS:
# - Email changes affect user identity and authentication
# - Audit logging for all approval/rejection actions
# - Token-based request identification prevents enumeration
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Handles email changes for all user types (direct, team, enterprise)
# - Maintains user identity integrity across all ecosystems
class Admin::Super::EmailChangeRequestsController < Admin::Super::BaseController
  include Pundit::Authorization
  before_action :set_email_change_request, only: [ :show, :approve, :reject ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # Display paginated list of email change requests for super admin review
  #
  # REQUEST DATA:
  # - All email change requests across the platform
  # - Includes user and approver information for context
  # - Recent requests first for timely processing
  #
  # SECURITY:
  # - Uses Pundit policy_scope (though super admin sees all)
  # - Includes associations to prevent N+1 queries
  #
  # WORKFLOW SUPPORT:
  # - Shows pending requests requiring action
  # - Displays approved/rejected history for audit
  # - Helps prioritize time-sensitive requests
  def index
    @email_change_requests = policy_scope(EmailChangeRequest).includes(:user, :approved_by)
                                                            .recent
    @pagy, @email_change_requests = pagy(@email_change_requests)
  end

  # Display detailed email change request for super admin review
  #
  # REQUEST DETAILS:
  # - Current email and requested new email
  # - Request timestamp and expiration
  # - User context and justification (if provided)
  #
  # SECURITY:
  # - Uses Pundit authorization to verify super admin access
  # - Token-based lookup prevents request enumeration
  #
  # WORKFLOW CONTEXT:
  # - Provides all information needed for approval decision
  # - Shows request history and current status
  def show
    authorize @email_change_request, :show?
  end

  # Approve email change request with audit logging
  #
  # APPROVAL PROCESS:
  # - Updates user's email to requested new email
  # - Records approval timestamp and approving admin
  # - Sends notification to user about approval
  #
  # AUDIT REQUIREMENTS:
  # - Records who approved the change and when
  # - Optional notes for approval reasoning
  # - Full audit trail for security compliance
  #
  # BUSINESS LOGIC:
  # - Validates request is still valid (not expired)
  # - Ensures requested email is still available
  # - Handles user authentication updates
  #
  # ERROR HANDLING:
  # - Shows specific error messages if approval fails
  # - Maintains request state if approval process fails
  def approve
    authorize @email_change_request, :approve?

    if @email_change_request.approve!(current_user, notes: params[:notes])
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  notice: "Email change request approved successfully."
    else
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  alert: "Failed to approve email change request: #{@email_change_request.errors.full_messages.join(', ')}"
    end
  end

  # Reject email change request with mandatory reasoning
  #
  # REJECTION REQUIREMENTS:
  # - Rejection reason (notes) is mandatory for audit compliance
  # - Records rejection timestamp and rejecting admin
  # - Sends notification to user explaining rejection
  #
  # AUDIT TRAIL:
  # - Records who rejected the change and when
  # - Mandatory notes explain rejection reasoning
  # - Full documentation for compliance and user communication
  #
  # BUSINESS LOGIC:
  # - User can submit new request after rejection
  # - Original request marked as rejected (not deleted)
  # - User notified with rejection reasoning for transparency
  #
  # VALIDATION:
  # - Enforces mandatory notes before processing rejection
  # - Prevents rejection without proper documentation
  def reject
    authorize @email_change_request, :reject?

    if params[:notes].blank?
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  alert: "Rejection reason is required."
      return
    end

    if @email_change_request.reject!(current_user, notes: params[:notes])
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  notice: "Email change request rejected."
    else
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  alert: "Failed to reject email change request: #{@email_change_request.errors.full_messages.join(', ')}"
    end
  end

  private

  # Find email change request by secure token
  #
  # SECURITY:
  # - Uses secure token instead of ID to prevent enumeration
  # - find_by! raises 404 if token is invalid or expired
  # - Token-based lookup adds security layer
  def set_email_change_request
    @email_change_request = EmailChangeRequest.find_by!(token: params[:token])
  end
end
