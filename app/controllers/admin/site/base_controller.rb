class Admin::Site::BaseController < ApplicationController
  include ActivityTrackable

  layout "modern_user"
  before_action :require_site_admin!

  private

  def require_site_admin!
    unless current_user&.site_admin? || current_user&.super_admin?
      flash[:alert] = "You must be a site admin to access this area."
      redirect_to root_path
    end
  end
end
