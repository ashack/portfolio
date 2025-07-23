# frozen_string_literal: true

module NavigationEngine
  class NavigationItem
    attr_reader :key, :label, :path, :icon, :children, :badge, :permission,
                :condition, :external, :method, :path_helper, :path_args

    def initialize(attributes = {})
      @key = attributes[:key]
      @label = attributes[:label]
      @path = attributes[:path]
      @path_helper = attributes[:path_helper]
      @path_args = attributes[:path_args] || {}
      @icon = attributes[:icon]
      @children = build_children(attributes[:children] || attributes[:items] || [])
      @badge = attributes[:badge]
      @permission = attributes[:permission]
      @condition = attributes[:condition]
      @external = attributes[:external] || false
      @method = (attributes[:method] || :get).to_sym
    end

    def has_children?
      children.any?
    end

    def resolved_label(context = nil)
      return label unless label.is_a?(String) && label.start_with?(".")

      I18n.t("#{NavigationEngine.i18n_scope}#{label}")
    end

    def resolved_path(context)
      return path if path.present?
      return "#" unless path_helper

      if context.respond_to?(path_helper)
        args = resolve_path_args(context)
        context.send(path_helper, args)
      else
        Rails.logger.warn "NavigationEngine: Helper method '#{path_helper}' not found"
        "#"
      end
    rescue StandardError => e
      Rails.logger.error "NavigationEngine: Error resolving path - #{e.message}"
      "#"
    end

    def visible?(user, context = nil)
      return false unless check_permission(user)
      return false unless check_condition(user, context)
      true
    end

    private

    def build_children(children_data)
      return [] unless children_data.is_a?(Array)

      children_data.map do |child_data|
        child_data.is_a?(NavigationItem) ? child_data : NavigationItem.new(child_data)
      end
    end

    def check_permission(user)
      return true unless permission

      case permission
      when Symbol
        user.respond_to?(permission) && user.send(permission)
      when String
        check_string_permission(user, permission)
      when Proc
        permission.call(user)
      else
        true
      end
    end

    def check_string_permission(user, permission_string)
      # Support dot notation like "team.admin?" or "can? :manage, :users"
      if permission_string.include?(".")
        object, method = permission_string.split(".", 2)
        user.send(object)&.send(method)
      elsif permission_string.start_with?("can?")
        # For CanCan/Pundit style permissions
        eval(permission_string) # Note: Be careful with eval in production
      else
        user.respond_to?(permission_string) && user.send(permission_string)
      end
    rescue StandardError => e
      Rails.logger.error "NavigationEngine: Error checking permission - #{e.message}"
      false
    end

    def check_condition(user, context)
      return true unless condition

      case condition
      when Proc
        condition.call(user, context)
      when String
        eval(condition) # Note: Be careful with eval in production
      else
        true
      end
    rescue StandardError => e
      Rails.logger.error "NavigationEngine: Error checking condition - #{e.message}"
      false
    end

    def resolve_path_args(context)
      return {} if path_args.empty?

      path_args.transform_values do |value|
        case value
        when Symbol
          if value.to_s.start_with?("@")
            # Instance variable from context
            context.instance_variable_get(value)
          elsif context.respond_to?(value)
            context.send(value)
          else
            value
          end
        when String
          value.gsub(/\{\{(\w+)\}\}/) do |match|
            method = $1.to_sym
            context.respond_to?(method) ? context.send(method) : match
          end
        else
          value
        end
      end
    end
  end
end
