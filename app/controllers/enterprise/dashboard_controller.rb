class Enterprise::DashboardController < Enterprise::BaseController
  skip_after_action :verify_policy_scoped, only: [:index]
  skip_after_action :verify_authorized, only: [:index]
  
  def index
    @members = @enterprise_group.users.includes(:enterprise_group)
    @is_admin = current_user.enterprise_admin?
  end
end