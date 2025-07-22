# Development showcase controller for Devise authentication views
# Displays all available Devise views and forms for UI development/testing
# Useful for designers and developers to see all authentication screens
class DeviseShowcaseController < ApplicationController
  # Allow public access to view authentication forms
  skip_before_action :authenticate_user!
  # Skip authorization - this is a development showcase
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /devise_showcase
  # Display showcase page with links to all Devise authentication views
  # Helps developers and designers see all auth forms in one place
  def index
    # Render showcase page - view contains links to all Devise forms
    # (login, registration, password reset, confirmation, etc.)
  end
end
