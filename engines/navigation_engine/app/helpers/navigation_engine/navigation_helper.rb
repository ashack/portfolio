# frozen_string_literal: true

module NavigationEngine
  module NavigationHelper
    # Render navigation for the current user with the specified style
    def navigation_for(user, style: :sidebar)
      return "" unless user

      component = NavigationComponent.new(
        user: user,
        request: request,
        view_context: self,
        style: style
      )

      component.render
    end

    # Check if a given path or pattern is active
    def active_nav?(path_or_pattern, exact: false)
      current = request.path

      case path_or_pattern
      when String
        if exact
          current == path_or_pattern
        else
          # Check if current path starts with the given path
          if path_or_pattern != "#" && path_or_pattern != "/" && current.start_with?(path_or_pattern)
            # Make sure it's not a partial match
            next_char = current[path_or_pattern.length]
            next_char.nil? || next_char == "/" || next_char == "?"
          else
            current == path_or_pattern
          end
        end
      when Regexp
        current.match?(path_or_pattern)
      when Array
        path_or_pattern.any? { |path| active_nav?(path, exact: exact) }
      else
        false
      end
    end

    # Helper to render navigation icon
    def nav_icon(icon_name, options = {})
      return "" unless icon_name

      default_class = "h-5 w-5 flex-shrink-0"
      icon_class = options.delete(:class) || default_class

      if respond_to?(:icon)
        icon(icon_name, class: icon_class, **options)
      else
        content_tag(:span, "", class: "#{icon_class} navigation-icon", data: { icon: icon_name })
      end
    end

    # Helper to render navigation badge
    def nav_badge(content, type: :default)
      return "" unless content

      badge_classes = case type
      when :danger
        "bg-red-100 text-red-600"
      when :warning
        "bg-yellow-100 text-yellow-600"
      when :success
        "bg-green-100 text-green-600"
      else
        "bg-gray-100 text-gray-600"
      end

      content_tag(:span, content, class: "ml-auto inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{badge_classes}")
    end

    # Get the current navigation structure
    def current_navigation
      return [] unless current_user

      builder = NavigationBuilder.new(
        user: current_user,
        request: request,
        view_context: self
      )

      builder.build
    end

    # Check if user can see a specific navigation item
    def can_see_nav_item?(item_key)
      current_navigation.any? do |item|
        find_nav_item(item, item_key).present?
      end
    end

    private

    def find_nav_item(item, key)
      return item if item[:key] == key

      if item[:items]
        item[:items].each do |sub_item|
          found = find_nav_item(sub_item, key)
          return found if found
        end
      end

      if item[:children]
        item[:children].each do |child|
          found = find_nav_item(child, key)
          return found if found
        end
      end

      nil
    end
  end
end
