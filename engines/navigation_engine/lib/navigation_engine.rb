# frozen_string_literal: true

require "navigation_engine/version"
require "navigation_engine/engine"

module NavigationEngine
  mattr_accessor :configuration_file
  @@configuration_file = "config/navigation.yml"

  mattr_accessor :cache_navigation
  @@cache_navigation = true

  mattr_accessor :cache_expires_in
  @@cache_expires_in = 1.hour

  mattr_accessor :i18n_scope
  @@i18n_scope = "navigation"

  mattr_accessor :default_icon_library
  @@default_icon_library = "phosphor"

  mattr_accessor :user_type_method
  @@user_type_method = :user_type

  mattr_accessor :admin_check_methods
  @@admin_check_methods = {
    super_admin: :super_admin?,
    site_admin: :site_admin?
  }

  def self.setup
    yield self
  end

  def self.configuration
    @configuration ||= load_configuration
  end

  def self.reload!
    @configuration = load_configuration
  end

  private

  def self.load_configuration
    config_path = Rails.root.join(configuration_file)

    unless File.exist?(config_path)
      Rails.logger.warn "NavigationEngine: Configuration file not found at #{config_path}"
      return {}
    end

    YAML.load_file(config_path).deep_symbolize_keys
  rescue StandardError => e
    Rails.logger.error "NavigationEngine: Error loading configuration - #{e.message}"
    {}
  end
end
