# Development debugging controller for authentication and session issues
# Provides detailed information about Devise, Warden, and session state
# ONLY for development/debugging - should not be accessible in production
class AuthDebugController < ApplicationController
  # Allow access without authentication for debugging login issues
  skip_before_action :authenticate_user!
  # Skip authorization - this is a debugging tool
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /auth_debug
  # Display comprehensive authentication and session debugging information
  # Helps developers troubleshoot login, session, and authentication issues
  def index
    # Safely get session key configuration
    session_key = begin
      Rails.application.config.session_options[:key]
    rescue
      "default"
    end

    # Get Warden user if available (underlying authentication layer)
    warden_user = defined?(warden) ? warden.user : nil

    # Compile comprehensive debugging information
    @debug_info = {
      # Session and authentication state
      session_info: {
        session_id: session.id,
        session_store: Rails.application.config.session_store,
        session_key: session_key,
        user_signed_in: user_signed_in?,
        current_user_id: current_user&.id,
        warden_user: warden_user
      },
      # Devise configuration and state
      devise_info: {
        devise_modules: User.devise_modules,
        mappings: Devise.mappings.keys,
        devise_controller: devise_controller?
      },
      # Database state for debugging
      user_count: User.count,
      first_user: User.first&.attributes&.slice("id", "email", "status", "confirmed_at")
    }
  end
end
