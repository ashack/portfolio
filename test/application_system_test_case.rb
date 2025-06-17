require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Include Devise helpers for system tests
  include Devise::Test::IntegrationHelpers

  # Helper to take screenshot on test failure
  def take_failed_screenshot
    return unless failed? && supports_screenshot?
    take_screenshot
  end

  teardown do
    take_failed_screenshot
  end
end
