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
    @members = @enterprise_group.users.includes(:enterprise_group_role)
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

    if @enterprise_group.save
      # Create the enterprise admin user
      if params[:admin_email].present?
        create_enterprise_admin(params[:admin_email])
      end

      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  notice: "Enterprise group was successfully created."
    else
      @enterprise_plans = Plan.for_enterprise.active
      @available_admins = User.direct_users.active.where(owns_team: false)
      render :new, status: :unprocessable_entity
    end
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

  def create_enterprise_admin(email)
    # Create new user as enterprise admin
    user = User.create!(
      email: email,
      password: SecureRandom.hex(16), # Temporary password
      user_type: "enterprise",
      enterprise_group: @enterprise_group,
      enterprise_group_role: "admin",
      status: "active",
      skip_confirmation: true # They'll set password on first login
    )

    @enterprise_group.update!(admin: user)

    # Send invitation email
    EnterpriseGroupMailer.admin_invitation(user, @enterprise_group).deliver_later
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create enterprise admin: #{e.message}"
  end
end
