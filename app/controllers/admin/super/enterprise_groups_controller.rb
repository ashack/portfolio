# Super Admin Enterprise Groups Controller
#
# PURPOSE:
# Provides complete CRUD interface for enterprise groups that super admins can create,
# manage, and oversee. Enterprise groups are invitation-only organizations for large customers.
#
# ACCESS RESTRICTIONS:
# - Super admins have full CRUD capabilities for enterprise groups
# - Can create enterprise groups and assign admin via invitation
# - Full access to enterprise group management and member oversight
# - Uses explicit admin check (allows both super and site admin access)
#
# BUSINESS RULES:
# - Only super admins can CREATE enterprise groups
# - Enterprise admin assigned via email invitation during creation
# - Cannot delete enterprise groups with active members
# - Enterprise groups are separate ecosystem from teams and direct users
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Enterprise groups are third track (separate from direct users and teams)
# - Members are invitation-only and cannot be other user types
# - Completely independent billing and management structure
#
# AUDIT & ACTIVITY:
# - Includes ActivityTrackable for admin action logging
# - All enterprise group actions tracked for security compliance
class Admin::Super::EnterpriseGroupsController < ApplicationController
  include ActivityTrackable
  include Paginatable

  before_action :require_admin!
  before_action :set_enterprise_group, only: [ :show, :edit, :update, :destroy ]

  # Display paginated list of all enterprise groups for super admin management
  #
  # ENTERPRISE DATA:
  # - All enterprise groups in the system
  # - Includes admin and plan information for management context
  # - Recent groups first for management relevance
  #
  # SECURITY:
  # - Uses Pundit policy_scope for authorization consistency
  # - Includes associations to prevent N+1 queries
  #
  # MANAGEMENT USE CASES:
  # - Overview of all enterprise customers
  # - Monitor enterprise group growth and status
  # - Access individual enterprise group management
  def index
    @enterprise_groups = policy_scope(EnterpriseGroup).includes(:admin, :plan)
                                                      .order(created_at: :desc)
    @pagy, @enterprise_groups = pagy(@enterprise_groups, items: @items_per_page, page: @page)
  end

  # Display detailed enterprise group information with member overview
  #
  # ENTERPRISE DETAILS:
  # - Enterprise group settings and configuration
  # - Current members and their roles
  # - Plan and billing status information
  #
  # SECURITY:
  # - Uses Pundit authorization to verify admin access
  # - Shows sensitive enterprise information to authorized admins
  #
  # MANAGEMENT CONTEXT:
  # - Complete enterprise group overview for administration
  # - Member management context and invitation status
  def show
    authorize @enterprise_group
    @members = @enterprise_group.users
  end

  # Display new enterprise group creation form
  #
  # FORM SETUP:
  # - New enterprise group instance for form binding
  # - Available enterprise plans for selection
  # - Available admins (direct users not owning teams)
  #
  # BUSINESS LOGIC:
  # - Only active enterprise plans shown
  # - Admin selection limited to eligible direct users
  # - Enterprise admin assigned via email invitation (not direct assignment)
  #
  # AUTHORIZATION:
  # - Verifies super admin can create enterprise groups
  def new
    @enterprise_group = EnterpriseGroup.new
    authorize @enterprise_group
    @enterprise_plans = Plan.for_enterprise.active
    @available_admins = User.direct_users.active.where(owns_team: false)
  end

  # Create enterprise group with admin invitation workflow
  #
  # CREATION PROCESS:
  # 1. Validate admin email is provided and unique
  # 2. Create enterprise group with super admin as creator
  # 3. Create invitation for designated admin
  # 4. Send invitation email to future admin
  #
  # VALIDATION RULES:
  # - Admin email is required for enterprise group creation
  # - Admin email must not already exist in system (new users only)
  # - Standard enterprise group validation (name, plan, etc.)
  #
  # INVITATION WORKFLOW:
  # - Creates invitation with "admin" role and "enterprise" type
  # - Records current super admin as inviter for audit trail
  # - Sends email invitation (immediate in dev, background in production)
  #
  # TRANSACTION SAFETY:
  # - Uses database transaction to ensure atomicity
  # - Rolls back if any step fails (group creation or invitation)
  # - Comprehensive error handling and logging
  #
  # BUSINESS RULES:
  # - Enterprise admins must be invited (not existing users)
  # - Only super admins can create enterprise groups
  # - Each enterprise group requires a designated admin
  def create
    @enterprise_group = EnterpriseGroup.new(enterprise_group_params)
    @enterprise_group.created_by = current_user
    authorize @enterprise_group

    # Validate admin email is present
    if params[:admin_email].blank?
      @enterprise_group.errors.add(:admin, "email must be provided")
      @enterprise_plans = Plan.for_enterprise.active
      render :new, status: :unprocessable_entity
      return
    end

    # Check if email already exists
    if User.exists?(email: params[:admin_email].downcase)
      @enterprise_group.errors.add(:admin, "email already has an account")
      @enterprise_plans = Plan.for_enterprise.active
      render :new, status: :unprocessable_entity
      return
    end

    # Create enterprise group and invitation in a transaction
    ActiveRecord::Base.transaction do
      # Save the enterprise group without an admin
      @enterprise_group.save!

      # Create invitation for the admin
      invitation = @enterprise_group.invitations.create!(
        email: params[:admin_email],
        role: "admin",
        invitation_type: "enterprise",
        invited_by: current_user
      )

      # Send invitation email
      if Rails.env.development?
        EnterpriseGroupMailer.admin_invitation(invitation, @enterprise_group).deliver_now
      else
        EnterpriseGroupMailer.admin_invitation(invitation, @enterprise_group).deliver_later
      end

      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  notice: "Enterprise group was successfully created. An invitation has been sent to #{params[:admin_email]}."
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create enterprise group: #{e.message}"
    @enterprise_plans = Plan.for_enterprise.active
    render :new, status: :unprocessable_entity
  end

  def edit
    authorize @enterprise_group
    @enterprise_plans = Plan.for_enterprise.active
  end

  def update
    authorize @enterprise_group
    if @enterprise_group.update(enterprise_group_params)
      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  notice: "Enterprise group was successfully updated."
    else
      @enterprise_plans = Plan.for_enterprise.active
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @enterprise_group
    if @enterprise_group.users.empty?
      @enterprise_group.destroy
      redirect_to admin_super_enterprise_groups_path,
                  notice: "Enterprise group was successfully deleted."
    else
      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  alert: "Cannot delete enterprise group with active members."
    end
  end

  private

  def require_admin!
    unless current_user&.super_admin? || current_user&.site_admin?
      flash[:alert] = "You must be an admin to access this area."
      redirect_to root_path
    end
  end

  def set_enterprise_group
    @enterprise_group = EnterpriseGroup.find_by!(slug: params[:id])
  end

  def enterprise_group_params
    params.require(:enterprise_group).permit(
      :name, :plan_id, :max_members, :trial_ends_at, :status
    )
  end
end
