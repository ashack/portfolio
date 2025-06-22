# Turbo Configuration
# Ensures Turbo works properly with Rails CSRF protection

Rails.application.config.after_initialize do
  # Configure Turbo to work with Rails authenticity tokens
  Rails.application.config.action_controller.default_protect_from_forgery = true
end
