# frozen_string_literal: true

require "application_system_test_case"

class PaginationStylingTest < ApplicationSystemTestCase
  setup do
    @super_admin = User.create!(
      email: "pagination_test_admin@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "Admin",
      system_role: "super_admin",
      confirmed_at: Time.current
    )
  end

  teardown do
    @super_admin.destroy!
  end

  test "pagination has proper Bootstrap styling" do
    sign_in @super_admin
    visit admin_super_users_path

    # Check if pagination wrapper exists
    assert_selector ".pagination-wrapper"

    # Check Bootstrap pagination classes
    assert_selector "nav[aria-label='Pagination Navigation']"
    assert_selector ".pagination"

    # Check for Bootstrap pagination item classes
    assert_selector ".page-item"
    assert_selector ".page-link"

    # Take screenshot for visual inspection
    take_screenshot
  end
end
