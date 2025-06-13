class AuthDebugController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
    session_key = begin
      Rails.application.config.session_options[:key]
    rescue
      "default"
    end

    warden_user = defined?(warden) ? warden.user : nil

    @debug_info = {
      session_info: {
        session_id: session.id,
        session_store: Rails.application.config.session_store,
        session_key: session_key,
        user_signed_in: user_signed_in?,
        current_user_id: current_user&.id,
        warden_user: warden_user
      },
      devise_info: {
        devise_modules: User.devise_modules,
        mappings: Devise.mappings.keys,
        devise_controller: devise_controller?
      },
      user_count: User.count,
      first_user: User.first&.attributes&.slice("id", "email", "status", "confirmed_at")
    }
  end
end
