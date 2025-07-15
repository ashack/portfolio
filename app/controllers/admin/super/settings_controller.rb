class Admin::Super::SettingsController < Admin::Super::BaseController
  def show
    # System-wide settings for super admin
  end

  def update
    # Handle settings updates
    flash[:notice] = "Settings updated successfully"
    redirect_to admin_super_settings_path
  end
end
