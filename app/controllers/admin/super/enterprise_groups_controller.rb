class Admin::Super::EnterpriseGroupsController < ApplicationController
  include ActivityTrackable

  layout "admin"
  before_action :require_admin!
  before_action :set_enterprise_group, only: [ :show, :edit, :update, :destroy ]

  def index
    @enterprise_groups = policy_scope(EnterpriseGroup).includes(:admin, :plan)
                                                      .order(created_at: :desc)
    @pagy, @enterprise_groups = pagy(@enterprise_groups)
  end

  def show
    authorize @enterprise_group
    @members = @enterprise_group.users
  end

  def new
    @enterprise_group = EnterpriseGroup.new
    authorize @enterprise_group
    @enterprise_plans = Plan.for_enterprise.active
    @available_admins = User.direct_users.active.where(owns_team: false)
  end

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
