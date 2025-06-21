class Enterprise::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_enterprise_user!
  before_action :set_enterprise_group
  before_action :verify_enterprise_group_access

  layout "enterprise"

  private

  def require_enterprise_user!
    unless current_user&.enterprise?
      flash[:alert] = "You must be an enterprise user to access this area."
      redirect_to root_path
    end
  end

  def set_enterprise_group
    @enterprise_group = current_user.enterprise_group
    unless @enterprise_group
      flash[:alert] = "No enterprise group found."
      redirect_to root_path
    end
  end

  def verify_enterprise_group_access
    # Verify the slug in the URL matches the user's enterprise group
    if params[:enterprise_group_slug] != @enterprise_group.slug
      flash[:alert] = "You don't have access to this enterprise group."
      redirect_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug)
    end
  end
end
