# frozen_string_literal: true

module NavigationEngine
  class ConfigurationLoader
    attr_reader :config_path, :cache_key

    def initialize(config_path = nil)
      @config_path = config_path || Rails.root.join(NavigationEngine.configuration_file)
      @cache_key = "navigation_engine/config/#{File.mtime(@config_path).to_i rescue 'default'}"
    end

    def load
      if NavigationEngine.cache_navigation
        Rails.cache.fetch(cache_key, expires_in: NavigationEngine.cache_expires_in) do
          load_from_file
        end
      else
        load_from_file
      end
    end

    def load_for_user(user)
      config = load
      user_type = user.send(NavigationEngine.user_type_method)

      if user.respond_to?(:admin?) && user.admin?
        load_admin_navigation(user, config)
      else
        config.dig(:navigation, user_type.to_sym) || config.dig(:navigation, :default) || []
      end
    end

    private

    def load_from_file
      return {} unless File.exist?(config_path)

      content = ERB.new(File.read(config_path)).result
      parsed = YAML.safe_load(content, aliases: true, permitted_classes: [ Symbol ])

      deep_transform_config(parsed)
    rescue StandardError => e
      Rails.logger.error "NavigationEngine: Error loading configuration - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {}
    end

    def load_admin_navigation(user, config)
      admin_config = config.dig(:navigation, :admin) || {}

      NavigationEngine.admin_check_methods.each do |admin_type, check_method|
        if user.respond_to?(check_method) && user.send(check_method)
          return admin_config[admin_type] || []
        end
      end

      []
    end

    def deep_transform_config(obj)
      case obj
      when Hash
        obj.deep_symbolize_keys.transform_values { |v| deep_transform_config(v) }
      when Array
        obj.map { |item| deep_transform_config(item) }
      when String
        # Transform special string patterns
        case obj
        when /^proc\s*\{(.+)\}$/
          # Convert proc strings to actual procs
          eval("Proc.new { #{$1} }")
        when /^:\w+$/
          # Convert symbol strings to symbols
          obj[1..-1].to_sym
        else
          obj
        end
      else
        obj
      end
    end
  end
end
