class Enterprise::SettingsController < Enterprise::BaseController
  before_action :require_admin!
  skip_after_action :verify_policy_scoped, only: [ :show ]
  skip_after_action :verify_authorized, only: [ :show, :update ]

  def show
    # Settings page
  end

  def update
    if @enterprise_group.update(settings_params)
      redirect_to settings_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Settings updated successfully"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def require_admin!
    unless current_user.enterprise_admin?
      redirect_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "You don't have permission to access settings"
    end
  end

  def settings_params
    params.require(:enterprise_group).permit(:name, :contact_email, :contact_phone,
                                            :billing_address, :max_members)
  end
end
