# frozen_string_literal: true

# NavigationEngine Configuration
NavigationEngine.setup do |config|
  # Path to your navigation YAML configuration file
  config.configuration_file = "config/navigation.yml"

  # Enable/disable navigation caching
  config.cache_navigation = Rails.env.production?

  # Cache expiration time
  config.cache_expires_in = 1.hour

  # I18n scope for navigation labels
  config.i18n_scope = "navigation"

  # Default icon library (e.g., "phosphor", "heroicons", "fontawesome")
  config.default_icon_library = "phosphor"

  # Method to determine user type on the user model
  config.user_type_method = :user_type

  # Methods to check for admin types
  config.admin_check_methods = {
    super_admin: :super_admin?,
    site_admin: :site_admin?
  }
end