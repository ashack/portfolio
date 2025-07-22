# Base controller for Site Admin area
# Provides common functionality for customer support and user management
# Site admins have read-only access compared to Super Admins
class Admin::Site::BaseController < ApplicationController
  # Include activity tracking for audit logs of admin actions
  include ActivityTrackable

  # Ensure only site admins or super admins can access these areas
  before_action :require_site_admin!

  private

  # Authorization check for site admin access
  # Allows both site_admin and super_admin roles
  # Super admins have access to all areas including site admin
  def require_site_admin!
    unless current_user&.site_admin? || current_user&.super_admin?
      flash[:alert] = "You must be a site admin to access this area."
      redirect_to root_path
    end
  end
end
