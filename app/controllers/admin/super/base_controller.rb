class Admin::Super::BaseController < ApplicationController
  include ActivityTrackable

  layout "admin"
  before_action :require_super_admin!

  private

  def require_super_admin!
    unless current_user&.super_admin?
      flash[:alert] = "You must be a super admin to access this area."
      redirect_to root_path
    end
  end
end
