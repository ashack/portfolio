# frozen_string_literal: true

module NavigationEngine
  class Engine < ::Rails::Engine
    isolate_namespace NavigationEngine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    initializer "navigation_engine.helpers" do
      ActiveSupport.on_load(:action_controller) do
        helper NavigationEngine::NavigationHelper
      end
    end

    initializer "navigation_engine.assets" do |app|
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
      app.config.assets.paths << root.join("app", "javascript")
    end

    config.to_prepare do
      # Reload navigation configuration in development
      NavigationEngine.reload! if Rails.env.development?
    end
  end
end
