# frozen_string_literal: true

module NavigationEngine
  class NavigationComponent
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Context

    attr_reader :user, :request, :view_context, :style, :navigation_items, :theme

    STYLES = [ :sidebar, :top_nav, :mobile ].freeze

    def initialize(user:, request:, view_context:, style: :sidebar)
      @user = user
      @request = request
      @view_context = view_context
      @style = style.to_sym
      @theme = determine_theme
      @navigation_items = build_navigation
    end

    def render
      view_context.render partial: partial_path, locals: locals
    end

    private

    def build_navigation
      builder = NavigationBuilder.new(user: user, request: request, view_context: view_context)
      style == :mobile ? builder.build_mobile : builder.build
    end

    def partial_path
      "navigation_engine/navigation/#{style}"
    end

    def locals
      {
        navigation_items: navigation_items,
        user: user,
        component: self
      }
    end

    def render_icon(icon_name, css_class: "")
      return "" unless icon_name

      if view_context.respond_to?(:icon)
        view_context.icon(
          icon_name,
          class: css_class
        )
      else
        view_context.content_tag(:span, "", class: "#{css_class} navigation-icon", data: { icon: icon_name })
      end
    end

    def render_badge(badge)
      return "" unless badge

      badge_text = badge.is_a?(Hash) ? badge[:text] : badge
      badge_type = badge.is_a?(Hash) ? (badge[:type] || :default) : :default

      badge_classes = case badge_type
      when :danger
        "bg-red-100 text-red-600"
      when :warning
        "bg-yellow-100 text-yellow-600"
      when :success
        "bg-green-100 text-green-600"
      else
        "bg-gray-100 text-gray-600"
      end

      view_context.content_tag(:span, badge_text, class: "ml-auto inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{badge_classes}")
    end

    def link_classes(item, base_classes = "")
      classes = [ base_classes ]

      if item[:active]
        classes << active_classes
      else
        classes << inactive_classes
      end

      classes.join(" ")
    end

    def active_classes
      case style
      when :sidebar
        if theme == :purple
          "bg-purple-50 text-purple-600"
        else
          "bg-gray-50 text-indigo-600"
        end
      when :top_nav
        "border-primary-500 text-gray-900"
      else
        "bg-gray-100 text-gray-900"
      end
    end

    def inactive_classes
      case style
      when :sidebar
        if theme == :purple
          "text-gray-700 hover:text-purple-600 hover:bg-purple-50"
        else
          "text-gray-700 hover:text-indigo-600 hover:bg-gray-50"
        end
      when :top_nav
        "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
      else
        "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
      end
    end

    def section_header_classes
      case style
      when :sidebar
        "text-xs font-semibold leading-6 text-gray-400"
      else
        "text-xs font-semibold leading-6 text-gray-500 uppercase tracking-wider"
      end
    end

    def icon_classes(item)
      base = "size-6 shrink-0"

      if item[:active]
        case style
        when :sidebar
          if theme == :purple
            "#{base} text-purple-600"
          else
            "#{base} text-indigo-600"
          end
        else
          "#{base} text-gray-900"
        end
      else
        case style
        when :sidebar
          if theme == :purple
            "#{base} text-gray-400 group-hover:text-purple-600"
          else
            "#{base} text-gray-400 group-hover:text-indigo-600"
          end
        else
          "#{base} text-gray-400 group-hover:text-gray-500"
        end
      end
    end

    def determine_theme
      return :purple if user.send(NavigationEngine.user_type_method) == "enterprise"
      :default
    end
  end
end
