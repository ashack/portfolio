class Admin::Super::UsersController < Admin::Super::BaseController
  include Paginatable

  before_action :set_user, only: [ :show, :edit, :update, :promote_to_site_admin, :demote_from_site_admin, :set_status, :activity, :impersonate, :reset_password, :confirm_email, :resend_confirmation, :unlock_account ]

  def index
    @users = policy_scope(User).includes(:team, :plan, :enterprise_group)

    # Apply filters
    @users = @users.where(user_type: params[:user_type]) if params[:user_type].present?
    @users = @users.where(status: params[:status]) if params[:status].present?

    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where(
        "email LIKE ? OR first_name LIKE ? OR last_name LIKE ?",
        search_term, search_term, search_term
      )
    end

    # Apply sorting
    @users = @users.order(created_at: :desc)

    # Paginate
    @pagy, @users = pagy(@users, items: @items_per_page, page: @page)
  end

  def show
    authorize @user
  end

  def edit
    authorize @user
  end

  def update
    authorize @user

    service = Users::UpdateService.new(current_user, @user, user_params, request)
    result = service.call

    if result.success?
      redirect_to admin_super_user_path(@user), notice: "User was successfully updated."
    else
      flash.now[:alert] = result.error
      render :edit, status: :unprocessable_entity
    end
  end

  def promote_to_site_admin
    authorize @user, :promote_to_site_admin?
    if @user.update(system_role: "site_admin")
      redirect_to admin_super_user_path(@user), notice: "User was promoted to site admin."
    else
      redirect_to admin_super_user_path(@user), alert: "Failed to promote user."
    end
  end

  def demote_from_site_admin
    authorize @user, :demote_from_site_admin?
    if @user.update(system_role: "user")
      redirect_to admin_super_user_path(@user), notice: "User was demoted from site admin."
    else
      redirect_to admin_super_user_path(@user), alert: "Failed to demote user."
    end
  end

  def set_status
    authorize @user, :set_status?
    service = Users::StatusManagementService.new(current_user, @user, params[:status], request)
    result = service.call

    if result.success?
      redirect_to admin_super_user_path(@user), notice: "User status was successfully updated."
    else
      redirect_to admin_super_user_path(@user), alert: result.error
    end
  end

  def activity
    authorize @user, :activity?
    @activities = @user.ahoy_visits.order(started_at: :desc).limit(50)
  end

  def impersonate
    authorize @user, :impersonate?

    AuditLogService.log_impersonate(
      admin_user: current_user,
      target_user: @user,
      request: request
    )

    sign_in(:user, @user)
    redirect_to root_path, notice: "Now impersonating #{@user.email}"
  end

  def reset_password
    authorize @user, :reset_password?

    service = Users::PasswordResetService.new(current_user, @user, request)
    result = service.call

    if result.success?
      redirect_to admin_super_user_path(@user), notice: "Password reset email sent to #{@user.email}"
    else
      redirect_to admin_super_user_path(@user), alert: result.error
    end
  end

  def confirm_email
    authorize @user, :confirm_email?

    service = Users::EmailConfirmationService.new(current_user, @user, request)
    result = service.call

    if result.success?
      redirect_to admin_super_user_path(@user), notice: "Email address confirmed for #{@user.email}"
    else
      redirect_to admin_super_user_path(@user), alert: result.error
    end
  end

  def resend_confirmation
    authorize @user, :resend_confirmation?

    service = Users::ResendConfirmationService.new(current_user, @user, request)
    result = service.call

    if result.success?
      redirect_to admin_super_user_path(@user), notice: "Confirmation email resent to #{@user.email}"
    else
      redirect_to admin_super_user_path(@user), alert: result.error
    end
  end

  def unlock_account
    authorize @user, :unlock_account?

    service = Users::AccountUnlockService.new(current_user, @user, request)
    result = service.call

    if result.success?
      redirect_to admin_super_user_path(@user), notice: "Account unlocked for #{@user.email}"
    else
      redirect_to admin_super_user_path(@user), alert: result.error
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted_params = params.require(:user).permit(:first_name, :last_name, :email, :system_role, :status)

    # Core business rule: never allow user_type changes
    if params[:user][:user_type].present?
      flash.now[:alert] = "User type cannot be changed - this is a core business rule"
    end

    # Core business rule: never allow direct team association changes
    if params[:user][:team_id].present? || params[:user][:team_role].present?
      flash.now[:alert] = "Team associations cannot be changed through user editing - use team management workflows"
    end

    # Additional validation: prevent editing own system_role at controller level
    if permitted_params[:system_role] && current_user.id == @user.id
      permitted_params.delete(:system_role)
      flash.now[:alert] = "You cannot change your own system role"
    end

    permitted_params
  end
end
