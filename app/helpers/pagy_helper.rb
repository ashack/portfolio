# frozen_string_literal: true

# PagyHelper provides custom Tailwind-styled pagination navigation
# Overrides default Pagy styling to match our design system
# 
# Features:
# - Responsive design (mobile vs desktop layouts)
# - Accessible navigation with ARIA labels
# - Turbo Frame support for AJAX updates
# - Custom styling matching Tailwind design system
# - Previous/Next icons on desktop, text on mobile
# - Current page highlighting
# - Disabled state styling
#
module PagyHelper
  include Pagy::Frontend

  # Generates a custom Tailwind-styled pagination navigation
  # @param pagy [Pagy] The Pagy instance containing pagination data
  # @param vars [Hash] Optional parameters:
  #   - link_extra: Extra HTML attributes for links (e.g., data-turbo-frame)
  #   - url: Custom URL builder lambda (defaults to pagy_url_for)
  # @return [String] HTML-safe pagination navigation markup
  def pagy_tailwind_nav(pagy, **vars)
    link_extra = vars[:link_extra] || ""
    url = vars[:url] || ->(page) { pagy_url_for(pagy, page) }

    html = <<~HTML
      <nav aria-label="Pagination Navigation" class="flex items-center justify-between">
        <div class="flex-1 flex justify-between sm:hidden">
          #{tailwind_prev_link(pagy, link_extra, url)}
          <span class="relative inline-flex items-center px-6 py-3 text-base font-medium text-gray-700">
            Page #{pagy.page} of #{pagy.pages}
          </span>
          #{tailwind_next_link(pagy, link_extra, url)}
        </div>
        <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-center">
          <div>
            <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
              #{tailwind_prev_link(pagy, link_extra, url, desktop: true)}
              #{tailwind_page_links(pagy, link_extra, url)}
              #{tailwind_next_link(pagy, link_extra, url, desktop: true)}
            </nav>
          </div>
        </div>
      </nav>
    HTML

    html.html_safe
  end

  private

  # Generates the "Previous" link or disabled span
  # @param pagy [Pagy] The Pagy instance
  # @param link_extra [String] Extra HTML attributes for the link
  # @param url [Proc] URL builder lambda
  # @param desktop [Boolean] Whether to render desktop version with icon
  # @return [String] HTML for previous link/span
  def tailwind_prev_link(pagy, link_extra, url, desktop: false)
    if pagy.prev
      link_to url.call(pagy.prev),
        class: tailwind_prev_link_classes(desktop),
        data: { turbo_frame: link_extra.match(/data-turbo-frame=['"]([^'"]+)['"]/i)&.[](1) } do
        if desktop
          <<~HTML.html_safe
            <span class="sr-only">Previous</span>
            <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
            </svg>
          HTML
        else
          "Previous"
        end
      end
    else
      content_tag :span, class: tailwind_prev_link_classes(desktop, disabled: true) do
        if desktop
          <<~HTML.html_safe
            <span class="sr-only">Previous</span>
            <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
            </svg>
          HTML
        else
          "Previous"
        end
      end
    end
  end

  # Generates the "Next" link or disabled span
  # @param pagy [Pagy] The Pagy instance
  # @param link_extra [String] Extra HTML attributes for the link
  # @param url [Proc] URL builder lambda
  # @param desktop [Boolean] Whether to render desktop version with icon
  # @return [String] HTML for next link/span
  def tailwind_next_link(pagy, link_extra, url, desktop: false)
    if pagy.next
      link_to url.call(pagy.next),
        class: tailwind_next_link_classes(desktop),
        data: { turbo_frame: link_extra.match(/data-turbo-frame=['"]([^'"]+)['"]/i)&.[](1) } do
        if desktop
          <<~HTML.html_safe
            <span class="sr-only">Next</span>
            <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
            </svg>
          HTML
        else
          "Next"
        end
      end
    else
      content_tag :span, class: tailwind_next_link_classes(desktop, disabled: true) do
        if desktop
          <<~HTML.html_safe
            <span class="sr-only">Next</span>
            <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
            </svg>
          HTML
        else
          "Next"
        end
      end
    end
  end

  # Generates the numbered page links with gaps
  # Handles three types of series items:
  # - Integer: clickable page number
  # - String: current page (highlighted)
  # - :gap: ellipsis for skipped pages
  # @param pagy [Pagy] The Pagy instance
  # @param link_extra [String] Extra HTML attributes for links
  # @param url [Proc] URL builder lambda
  # @return [String] HTML for all page links
  def tailwind_page_links(pagy, link_extra, url)
    series = pagy.series

    series.map.with_index do |item, index|
      case item
      when Integer
        # Regular page number link
        # First item needs all borders, others need top, bottom, right
        border_class = index == 0 ? "border" : "border-t border-b border-r"
        link_to item.to_s, url.call(item),
          class: "relative inline-flex items-center px-6 py-3 text-base font-semibold text-gray-900 #{border_class} border-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0",
          data: { turbo_frame: link_extra.match(/data-turbo-frame=['"]([^'"]+)['"]/i)&.[](1) }
      when String  # Current page (Pagy returns current page as string)
        # Highlighted with indigo background and white text
        border_class = index == 0 ? "border" : "border-t border-b border-r"
        content_tag :span,
          class: "relative inline-flex items-center px-6 py-3 text-base font-semibold text-white bg-indigo-600 #{border_class} border-indigo-600 cursor-default z-10 focus:z-20 focus:outline-offset-0",
          "aria-current": "page" do
          item
        end
      when :gap
        # Ellipsis for skipped page numbers
        border_class = index == 0 ? "border" : "border-t border-b border-r"
        content_tag :span,
          class: "relative inline-flex items-center px-6 py-3 text-base font-semibold text-gray-700 #{border_class} border-gray-300 focus:outline-offset-0" do
          "..."
        end
      end
    end.join.html_safe
  end

  # Returns CSS classes for the Previous link/span
  # Different styles for desktop (icon) vs mobile (text)
  # @param desktop [Boolean] Whether desktop version
  # @param disabled [Boolean] Whether link is disabled
  # @return [String] CSS classes
  def tailwind_prev_link_classes(desktop, disabled: false)
    base = if desktop
      "relative inline-flex items-center rounded-l-md px-4 py-3 text-gray-400 border-t border-b border-l border-gray-300"
    else
      "relative inline-flex items-center px-6 py-3 text-base font-medium rounded-md border border-gray-300"
    end

    if disabled
      "#{base} #{desktop ? 'bg-gray-50 cursor-not-allowed' : 'text-gray-300 bg-gray-100 cursor-not-allowed'}"
    else
      "#{base} #{desktop ? 'hover:bg-gray-50 focus:z-20 focus:outline-offset-0' : 'text-gray-700 bg-white hover:bg-gray-50'}"
    end
  end

  # Returns CSS classes for the Next link/span
  # Different styles for desktop (icon) vs mobile (text)
  # @param desktop [Boolean] Whether desktop version
  # @param disabled [Boolean] Whether link is disabled
  # @return [String] CSS classes
  def tailwind_next_link_classes(desktop, disabled: false)
    base = if desktop
      "relative inline-flex items-center rounded-r-md px-4 py-3 text-gray-400 border border-gray-300"
    else
      "relative inline-flex items-center px-6 py-3 text-base font-medium rounded-md border border-gray-300"
    end

    if disabled
      "#{base} #{desktop ? 'bg-gray-50 cursor-not-allowed' : 'text-gray-300 bg-gray-100 cursor-not-allowed'}"
    else
      "#{base} #{desktop ? 'hover:bg-gray-50 focus:z-20 focus:outline-offset-0' : 'text-gray-700 bg-white hover:bg-gray-50'}"
    end
  end
end
