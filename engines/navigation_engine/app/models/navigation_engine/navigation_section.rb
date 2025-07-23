# frozen_string_literal: true

module NavigationEngine
  class NavigationSection
    attr_reader :key, :label, :items, :permission, :condition

    def initialize(attributes = {})
      @key = attributes[:key]
      @label = attributes[:label]
      @items = build_items(attributes[:items] || [])
      @permission = attributes[:permission]
      @condition = attributes[:condition]
    end

    def resolved_label
      return label unless label.is_a?(String) && label.start_with?(".")

      I18n.t("#{NavigationEngine.i18n_scope}#{label}")
    end

    def visible?(user, context = nil)
      return false unless check_permission(user)
      return false unless check_condition(user, context)
      items.any? { |item| item.visible?(user, context) }
    end

    private

    def build_items(items_data)
      return [] unless items_data.is_a?(Array)

      items_data.map do |item_data|
        item_data.is_a?(NavigationItem) ? item_data : NavigationItem.new(item_data)
      end
    end

    def check_permission(user)
      return true unless permission

      case permission
      when Symbol
        user.respond_to?(permission) && user.send(permission)
      when String
        user.respond_to?(permission) && user.send(permission)
      when Proc
        permission.call(user)
      else
        true
      end
    end

    def check_condition(user, context)
      return true unless condition

      case condition
      when Proc
        condition.call(user, context)
      else
        true
      end
    end
  end
end
