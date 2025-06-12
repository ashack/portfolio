class Admin::Super::UsersController < Admin::Super::BaseController
  before_action :set_user, only: [:show, :promote_to_site_admin, :demote_from_site_admin, :set_status, :activity, :impersonate]
  
  def index
    @users = policy_scope(User).order(created_at: :desc)
    @pagy, @users = pagy(@users)
  end
  
  def show
    authorize @user
  end
  
  def promote_to_site_admin
    authorize @user
    if @user.update(system_role: 'site_admin')
      redirect_to admin_super_user_path(@user), notice: 'User was promoted to site admin.'
    else
      redirect_to admin_super_user_path(@user), alert: 'Failed to promote user.'
    end
  end
  
  def demote_from_site_admin
    authorize @user
    if @user.update(system_role: 'user')
      redirect_to admin_super_user_path(@user), notice: 'User was demoted from site admin.'
    else
      redirect_to admin_super_user_path(@user), alert: 'Failed to demote user.'
    end
  end
  
  def set_status
    authorize @user
    service = Users::StatusManagementService.new(current_user, @user, params[:status])
    result = service.call
    
    if result.success?
      redirect_to admin_super_user_path(@user), notice: 'User status was successfully updated.'
    else
      redirect_to admin_super_user_path(@user), alert: result.error
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