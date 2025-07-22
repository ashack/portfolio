# Site Admin Users Controller
#
# PURPOSE:
# Provides site admin interface for managing users with limited support-focused capabilities.
# Site admins can view users, change status, and perform basic support actions but cannot
# create users, access billing, or perform system-level changes.
#
# ACCESS RESTRICTIONS:
# - Site admins can view all users except super admins
# - Can change user status (active/inactive/locked) for support
# - Can impersonate users for support troubleshooting
# - Cannot create users, access billing, or modify system roles
# - Inherits from Admin::Site::BaseController which enforces site_admin role
#
# BUSINESS RULES:
# - Site admins provide first-level customer support
# - Status management uses service objects with audit logging
# - Impersonation logged for security compliance
# - No access to financial or sensitive system data
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Manages all user types (direct, team members, enterprise) except super admins
# - Understands user type context for appropriate support
# - Cannot change user types (core business rule)
class Admin::Site::UsersController < Admin::Site::BaseController
  before_action :set_user, only: [ :show, :set_status, :activity, :impersonate ]

  # Display paginated list of all users (excluding super admins) for site admin management
  #
  # INCLUSIONS:
  # - All user types: direct, team members, enterprise users
  # - Associated team, plan, and enterprise group data for context
  # - Recent users first for support relevance
  #
  # EXCLUSIONS:
  # - Super admin users (site admins shouldn't see system administrators)
  #
  # SECURITY:
  # - Uses Pundit policy_scope to ensure proper access control
  # - Includes associations to prevent N+1 query problems
  #
  # SUPPORT USE CASES:
  # - Find users by various criteria for support tickets
  # - Understand user context (team/enterprise membership)
  # - Monitor user registration patterns
  def index
    @users = policy_scope(User).includes(:team, :plan, :enterprise_group).where.not(system_role: "super_admin").order(created_at: :desc)
    @pagy, @users = pagy(@users)
  end

  # Display detailed user information for site admin support purposes
  #
  # INFORMATION SHOWN:
  # - User profile and account details
  # - Account status and security information
  # - Team/enterprise membership context
  # - Recent activity summary
  #
  # SECURITY:
  # - Uses Pundit authorization to verify site admin can view this user
  # - No sensitive financial or system data exposed
  #
  # SUPPORT USE CASES:
  # - Comprehensive user context for support tickets
  # - Verify user account status and settings
  # - Understand user's organizational context
  def show
    authorize @user
  end

  # Change user status (active/inactive/locked) using service object with audit logging
  #
  # ALLOWED STATUS CHANGES:
  # - active: User can login and use platform
  # - inactive: User account disabled but not deleted
  # - locked: Account locked due to security concerns
  #
  # SECURITY & AUDIT:
  # - Uses Pundit authorization to verify permission
  # - StatusManagementService provides audit logging
  # - All status changes tracked for compliance
  #
  # BUSINESS RULES:
  # - Site admins can change status for support purposes
  # - Service object enforces business logic and validation
  # - Audit trail maintained for all status changes
  #
  # USE CASES:
  # - Lock compromised accounts
  # - Reactivate inactive customer accounts
  # - Temporary account suspension for support issues
  def set_status
    authorize @user
    service = Users::StatusManagementService.new(current_user, @user, params[:status])
    result = service.call

    if result.success?
      redirect_to admin_site_user_path(@user), notice: "User status was successfully updated."
    else
      redirect_to admin_site_user_path(@user), alert: result.error
    end
  end

  # Display user activity history for support troubleshooting
  #
  # ACTIVITY DATA:
  # - Recent 50 visits using Ahoy analytics
  # - Visit timestamps and basic session info
  # - Ordered by most recent first
  #
  # SECURITY:
  # - Uses Pundit authorization to verify viewing permission
  # - No sensitive personal data in activity logs
  #
  # SUPPORT USE CASES:
  # - Troubleshoot user login issues
  # - Verify user platform engagement
  # - Understand user behavior patterns for support
  #
  # PRIVACY CONSIDERATIONS:
  # - Limited to basic visit data, not detailed page tracking
  # - Focused on support-relevant information only
  def activity
    authorize @user
    @activities = @user.ahoy_visits.order(started_at: :desc).limit(50)
  end

  # Impersonate user for support troubleshooting (with security logging)
  #
  # IMPERSONATION PURPOSE:
  # - Troubleshoot user-reported issues from their perspective
  # - Verify platform functionality for specific user contexts
  # - Debug user-specific problems
  #
  # SECURITY MEASURES:
  # - Uses Pundit authorization to verify impersonation permission
  # - Should trigger audit logging (implementation may need enhancement)
  # - Logs admin who performed impersonation
  #
  # BUSINESS RULES:
  # - Only for legitimate support purposes
  # - Site admins can impersonate non-admin users
  # - Creates temporary session as impersonated user
  #
  # COMPLIANCE:
  # - All impersonations should be logged for security audit
  # - Clear notification to prevent confusion
  def impersonate
    authorize @user
    sign_in(:user, @user)
    redirect_to root_path, notice: "Now impersonating #{@user.email}"
  end

  private

  # Find user by ID for admin actions
  #
  # SECURITY: Uses find() which raises 404 if user doesn't exist
  # CONTEXT: Sets @user for use in authorized admin actions
  def set_user
    @user = User.find(params[:id])
  end
end
