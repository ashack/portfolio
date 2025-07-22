# Base controller for Super Admin area
# Provides highest level platform administration functionality
# Only super admins have access - can create teams, manage billing, system settings
class Admin::Super::BaseController < ApplicationController
  # Include activity tracking for comprehensive audit logs of platform changes
  include ActivityTrackable

  # Restrict access to super admins only
  before_action :require_super_admin!

  private

  # Authorization check for super admin access
  # Most restrictive - only allows super_admin role
  # Super admins have full platform control including team creation
  def require_super_admin!
    unless current_user&.super_admin?
      flash[:alert] = "You must be a super admin to access this area."
      redirect_to root_path
    end
  end
end
