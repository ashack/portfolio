class Admin::Site::UsersController < Admin::Site::BaseController
  before_action :set_user, only: [ :show, :set_status, :activity, :impersonate ]

  def index
    @users = policy_scope(User).includes(:team, :plan, :enterprise_group).where.not(system_role: "super_admin").order(created_at: :desc)
    @pagy, @users = pagy(@users)
  end

  def show
    authorize @user
  end

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

  def activity
    authorize @user
    @activities = @user.ahoy_visits.order(started_at: :desc).limit(50)
  end

  def impersonate
    authorize @user
    sign_in(:user, @user)
    redirect_to root_path, notice: "Now impersonating #{@user.email}"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
