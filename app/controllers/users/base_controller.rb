# Base controller for direct user functionality
# Ensures only direct users (not invited/enterprise) can access personal features
# Part of the triple-track user system access control
class Users::BaseController < ApplicationController
  # Restrict access to direct users only
  before_action :require_direct_user!

  private

  # Authorization check for direct user access
  # Direct users have individual accounts with personal billing and features
  # Invited and enterprise users use team/organization features instead
  def require_direct_user!
    unless current_user&.direct?
      flash[:alert] = "This area is only accessible to direct users."
      redirect_to root_path
    end
  end
end
