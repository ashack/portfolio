# frozen_string_literal: true

# Pagy Configuration
# =================
# This initializer configures the Pagy pagination gem for the application.
# We use a custom Tailwind helper (PagyHelper) instead of the pagy/extras/tailwind
# because it doesn't exist in the current version and we need custom styling.
#
# Loaded extras:
# - overflow: Handles requests for pages beyond the last page
# - metadata: Provides pagination metadata for API responses
# - i18n: Internationalization support for pagination text
#
require "pagy/extras/overflow"
require "pagy/extras/metadata"
require "pagy/extras/i18n"

# Default items per page
# This can be overridden by user preferences via the Paginatable concern
# Must match DEFAULT_PER_PAGE in Paginatable concern
Pagy::DEFAULT[:items] = 20

# Overflow handling strategy
# When users request a page beyond the last page (e.g., page 999 of 10),
# redirect to the last valid page instead of showing an error
# Options: :last_page, :empty_page, :exception
Pagy::DEFAULT[:overflow] = :last_page

# Pagination UI configuration
# Controls which page numbers are shown in the navigation
# Format: [pages_at_start, pages_before_current, pages_after_current, pages_at_end]
# Example with [1, 4, 4, 1] on page 10 of 20: 1 ... 6 7 8 9 [10] 11 12 13 14 ... 20
# This ensures the current page is always visible with context
Pagy::DEFAULT[:size] = [ 1, 4, 4, 1 ]

# Responsive breakpoints for different screen sizes
# Adjusts the number of page links shown based on viewport width
# Mobile (0-539px): Show fewer pages to fit small screens
# Tablet (540-719px): Show moderate number of pages
# Desktop (720px+): Show full pagination
Pagy::DEFAULT[:breakpoints] = { 
  0 => [ 1, 2, 2, 1 ],    # Mobile: 1 ... 8 9 [10] 11 12 ... 20
  540 => [ 1, 3, 3, 1 ],  # Tablet: 1 ... 7 8 9 [10] 11 12 13 ... 20
  720 => [ 1, 4, 4, 1 ]   # Desktop: 1 ... 6 7 8 9 [10] 11 12 13 14 ... 20
}

# Metadata configuration for API responses
# When using Pagy in API controllers, these fields will be included
# in the pagination metadata object
# Useful for building custom pagination UIs in frontend frameworks
Pagy::DEFAULT[:metadata] = [ 
  :scaffold_url,  # URL template for generating page links
  :page,          # Current page number
  :prev,          # Previous page number (or nil)
  :next,          # Next page number (or nil)
  :last,          # Last page number
  :items,         # Items per page
  :count,         # Total number of items
  :pages,         # Total number of pages
  :from,          # First item number on current page
  :to             # Last item number on current page
]

# Internationalization (i18n) configuration
# Loads custom translations for pagination text
# The pagy.en.yml file can customize text like "Previous", "Next", etc.
# Additional languages can be added by creating pagy.{locale}.yml files
Pagy::I18n.load(locale: "en", filepath: Rails.root.join("config/locales/pagy.en.yml"))
