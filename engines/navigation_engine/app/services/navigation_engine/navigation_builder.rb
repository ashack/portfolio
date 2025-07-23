# frozen_string_literal: true

module NavigationEngine
  class NavigationBuilder
    attr_reader :user, :request, :view_context

    def initialize(user:, request:, view_context:)
      @user = user
      @request = request
      @view_context = view_context
    end

    def build
      navigation_config = load_navigation_config
      process_navigation_items(navigation_config)
    end

    def build_mobile
      items = build
      flatten_for_mobile(items)
    end

    private

    def load_navigation_config
      loader = ConfigurationLoader.new
      config_data = loader.load_for_user(user)

      build_navigation_objects(config_data)
    end

    def build_navigation_objects(config_data)
      return [] unless config_data.is_a?(Array) || config_data.is_a?(Hash)

      items = config_data.is_a?(Hash) ? config_data[:items] || config_data[:sections] || [] : config_data

      items.map do |item_data|
        if item_data[:items] || item_data[:type] == "section"
          NavigationSection.new(item_data)
        else
          NavigationItem.new(item_data)
        end
      end
    end

    def process_navigation_items(items)
      items.map do |item|
        next unless item.visible?(user, view_context)

        case item
        when NavigationSection
          process_section(item)
        when NavigationItem
          process_item(item)
        end
      end.compact
    end

    def process_section(section)
      processed_items = section.items.map { |item| process_item(item) }.compact
      return nil if processed_items.empty?

      {
        type: :section,
        key: section.key,
        label: section.resolved_label,
        items: processed_items
      }
    end

    def process_item(item)
      return nil unless item.visible?(user, view_context)

      processed_item = {
        type: :item,
        key: item.key,
        label: item.resolved_label(view_context),
        path: item.resolved_path(view_context),
        icon: item.icon,
        active: active?(item),
        external: item.external,
        method: item.method
      }

      # Add badge if present
      if item.badge
        processed_item[:badge] = resolve_badge(item.badge)
      end

      # Process children if present
      if item.has_children?
        processed_children = item.children.map { |child| process_item(child) }.compact
        processed_item[:children] = processed_children if processed_children.any?
      end

      processed_item
    end

    def resolve_badge(badge)
      case badge
      when Symbol
        if user.respond_to?(badge)
          user.send(badge)
        elsif view_context.respond_to?(badge)
          view_context.send(badge)
        else
          nil
        end
      when Proc
        badge.call(user, view_context)
      when Hash
        {
          text: badge[:text],
          type: badge[:type] || :default
        }
      else
        badge
      end
    end

    def active?(item)
      current_path = request.path
      item_path = item.resolved_path(view_context)

      # Skip if no valid path
      return false if item_path == "#" || item_path.blank?

      # Exact match
      return true if current_path == item_path

      # Check if current path starts with item path (for nested routes)
      if current_path.start_with?(item_path)
        # Make sure it's not a partial match
        next_char = current_path[item_path.length]
        return true if next_char.nil? || next_char == "/" || next_char == "?"
      end

      # Check children for active state
      if item.has_children?
        item.children.any? { |child| active?(child) }
      else
        false
      end
    end

    def flatten_for_mobile(items, parent_label = nil)
      flattened = []

      items.each do |item|
        if item[:type] == :section
          # Add section header
          flattened << {
            type: :header,
            label: item[:label]
          }
          # Add section items
          flattened.concat(flatten_for_mobile(item[:items], item[:label]))
        elsif item[:children]
          # Add parent item
          flattened << item.merge(has_children: true)
          # Add children with indentation
          item[:children].each do |child|
            flattened << child.merge(indented: true, parent: item[:key])
          end
        else
          flattened << item
        end
      end

      flattened
    end
  end
end
