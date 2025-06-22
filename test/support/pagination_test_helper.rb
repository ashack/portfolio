# frozen_string_literal: true

# PaginationTestHelper provides helper methods for testing pagination functionality
# Include this module in your test classes to simplify pagination testing
#
# Features:
# - Record creation helpers for pagination scenarios
# - Assertion helpers for pagination UI elements
# - Navigation helpers for interacting with pagination
# - Filter preservation testing
# - AJAX/Turbo Frame support
#
# Usage:
#   class YourIntegrationTest < ActionDispatch::IntegrationTest
#     include PaginationTestHelper
#     
#     test "pagination works correctly" do
#       create_paginated_records(User, 50)
#       visit users_path
#       assert_pagination_info(from: 1, to: 20, total: 50)
#       navigate_to_page(2)
#       assert_page_active(2)
#     end
#   end
#
module PaginationTestHelper
  # Creates multiple records for testing pagination
  # Records are created with staggered timestamps for consistent ordering
  # @param model_class [Class] The ActiveRecord model class to create
  # @param count [Integer] Number of records to create
  # @param attributes [Hash] Additional attributes for each record
  # @return [Array] Array of created records
  def create_paginated_records(model_class, count, attributes = {})
    Array.new(count) do |i|
      factory_name = model_class.name.underscore.to_sym
      create(factory_name, attributes.merge(created_at: i.hours.ago))
    end
  end

  # Asserts that the pagination results info is displayed correctly
  # Checks for text like "Showing 1 to 20 of 100 results"
  # @param from [Integer] First item number on current page
  # @param to [Integer] Last item number on current page  
  # @param total [Integer] Total number of items
  def assert_pagination_info(from:, to:, total:)
    assert_text "Showing #{from} to #{to} of #{total} results"
  end

  # Asserts that pagination navigation controls are present on the page
  # Checks for the main navigation container and pagination wrapper
  # Use this to verify pagination is rendered when expected
  def assert_pagination_controls_present
    assert_selector "nav[aria-label='Pagination Navigation']"
    assert_selector ".pagination"
  end

  # Asserts that a specific page number is marked as active/current
  # @param page_number [Integer] The page number that should be active
  def assert_page_active(page_number)
    within "nav[aria-label='Pagination Navigation']" do
      assert_selector ".active", text: page_number.to_s
    end
  end

  # Clicks on a specific page number link to navigate to that page
  # @param page_number [Integer] The page number to navigate to
  def navigate_to_page(page_number)
    within "nav[aria-label='Pagination Navigation']" do
      click_link page_number.to_s
    end
  end

  # Changes the items per page using the dropdown selector
  # This will submit the form and reload the page with new pagination
  # @param count [Integer] Number of items per page (10, 20, 50, or 100)
  def change_items_per_page(count)
    within ".items-per-page" do
      select count.to_s, from: "per_page"
    end
  end

  # Asserts that a specific items per page value is selected in the dropdown
  # @param count [Integer] The expected selected value
  def assert_items_per_page_selected(count)
    within ".items-per-page" do
      assert_select "select[name='per_page']", selected: count.to_s
    end
  end

  # Uses the page jump form to navigate directly to a specific page
  # Note: Page jump feature may be hidden by default
  # @param page_number [Integer] The page number to jump to
  def jump_to_page(page_number)
    within ".page-jump" do
      fill_in "page", with: page_number
      find("input[name='page']").native.send_keys(:return)
    end
  end

  # Asserts that filter parameters are preserved in all pagination links
  # This ensures filters don't get lost when navigating pages
  # @param params [Hash] The filter parameters that should be preserved
  # @example
  #   assert_filter_params_preserved(status: 'active', search: 'john')
  def assert_filter_params_preserved(params)
    within "nav[aria-label='Pagination Navigation']" do
      first_link = find("a", match: :first)
      uri = URI.parse(first_link[:href])
      query_params = Rack::Utils.parse_query(uri.query)

      params.each do |key, value|
        assert_equal value.to_s, query_params[key.to_s]
      end
    end
  end

  # Helper method to build a hash of pagination parameters
  # Useful for constructing URLs or form submissions
  # @param page [Integer] Page number (default: 1)
  # @param per_page [Integer] Items per page (default: 20)
  # @param filters [Hash] Additional filter parameters
  # @return [Hash] Combined pagination and filter parameters
  def pagination_params(page: 1, per_page: 20, **filters)
    { page: page, per_page: per_page }.merge(filters)
  end

  # Asserts that pagination controls are not shown
  # This should be true when there's only one page of results
  # or when there are no results at all
  def assert_pagination_hidden
    assert_no_selector "nav[aria-label='Pagination Navigation']"
  end

  # Asserts that pagination is in a loading state
  # Used when testing AJAX/Turbo Frame updates
  # Checks for the data-pagination-loading attribute
  def assert_pagination_loading
    assert_selector "[data-pagination-loading]"
  end

  # Waits for pagination to finish loading after an AJAX request
  # Use this after triggering pagination actions with Turbo Frames
  # @param timeout [Integer] Maximum seconds to wait (default: 5)
  def wait_for_pagination
    assert_no_selector "[data-pagination-loading]", wait: 5
  end
end
