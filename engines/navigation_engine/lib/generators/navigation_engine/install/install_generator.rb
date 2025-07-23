# frozen_string_literal: true

require "rails/generators/base"

module NavigationEngine
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs NavigationEngine and generates necessary files"

      def add_engine_to_gemfile
        gem "navigation_engine", path: "engines/navigation_engine"

        Bundler.with_unbundled_env do
          run "bundle install"
        end
      end

      def create_initializer
        template "navigation_engine.rb", "config/initializers/navigation_engine.rb"
      end

      def create_navigation_config
        template "navigation.yml", "config/navigation.yml"
      end

      def create_locale_file
        template "navigation.en.yml", "config/locales/navigation.en.yml"
      end

      def mount_engine_routes
        route 'mount NavigationEngine::Engine => "/navigation_engine"'
      end

      def add_helper_to_application_controller
        inject_into_file "app/controllers/application_controller.rb",
                         "  helper NavigationEngine::NavigationHelper\n",
                         after: "class ApplicationController < ActionController::Base\n"
      end

      def copy_stimulus_controllers
        directory "stimulus_controllers", "app/javascript/controllers"
      end

      def display_post_install_message
        say "\n✅ NavigationEngine has been successfully installed!\n", :green
        say "\nNext steps:", :yellow
        say "1. Configure your navigation in config/navigation.yml"
        say "2. Update your navigation labels in config/locales/navigation.en.yml"
        say "3. Replace your existing navigation with <%= navigation_for(current_user) %>"
        say "4. Customize the navigation partials if needed"
        say "\nFor more information, see the NavigationEngine documentation.\n"
      end

      private

      def application_controller_path
        Rails.root.join("app/controllers/application_controller.rb")
      end
    end
  end
end
