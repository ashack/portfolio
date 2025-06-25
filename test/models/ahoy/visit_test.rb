require "test_helper"

class Ahoy::VisitTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "visitor@example.com",
      password: "Password123!",
      first_name: "Visitor",
      last_name: "User"
    )
    @user.skip_confirmation!
    @user.save!

    @visit = Ahoy::Visit.new(
      visit_token: SecureRandom.uuid,
      visitor_token: SecureRandom.uuid,
      user: @user,
      ip: "192.168.1.100",
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
      referrer: "https://google.com",
      landing_page: "/",
      browser: "Chrome",
      os: "Mac OS X",
      device_type: "Desktop",
      started_at: Time.current
    )
  end

  test "should be valid with valid attributes" do
    assert @visit.valid?
  end

  test "should be valid without user" do
    @visit.user = nil
    assert @visit.valid?
  end

  test "should have many events" do
    @visit.save!

    event1 = Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "page_view",
      properties: { page: "/dashboard" },
      time: Time.current
    )

    event2 = Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "button_click",
      properties: { button: "save" },
      time: Time.current
    )

    assert_equal 2, @visit.events.count
    assert_includes @visit.events, event1
    assert_includes @visit.events, event2
  end

  test "belongs to user association" do
    @visit.save!
    assert_equal @user, @visit.user
    assert_includes @user.ahoy_visits, @visit
  end

  test "can track anonymous visits" do
    anonymous_visit = Ahoy::Visit.new(
      visit_token: SecureRandom.uuid,
      visitor_token: SecureRandom.uuid,
      user: nil,
      ip: "192.168.1.101",
      user_agent: "Mozilla/5.0",
      started_at: Time.current
    )

    assert anonymous_visit.valid?
    assert anonymous_visit.save
    assert_nil anonymous_visit.user
  end

  test "stores visit metadata" do
    @visit.save!
    @visit.reload

    assert_equal "192.168.1.100", @visit.ip
    assert_equal "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", @visit.user_agent
    assert_equal "https://google.com", @visit.referrer
    assert_equal "/", @visit.landing_page
    assert_equal "Chrome", @visit.browser
    assert_equal "Mac OS X", @visit.os
    assert_equal "Desktop", @visit.device_type
  end

  # Weight: 3 - Visit duration tracking (analytics feature)
  test "tracks visit duration" do
    skip "ended_at attribute doesn't exist in Ahoy::Visit"
  end

  test "can query visits by timeframe" do
    # Create visits at different times
    old_visit = Ahoy::Visit.create!(
      visit_token: SecureRandom.uuid,
      visitor_token: SecureRandom.uuid,
      started_at: 2.days.ago
    )

    recent_visit = Ahoy::Visit.create!(
      visit_token: SecureRandom.uuid,
      visitor_token: SecureRandom.uuid,
      started_at: 1.hour.ago
    )

    today_visits = Ahoy::Visit.where("started_at >= ?", Date.current.beginning_of_day)
    assert_includes today_visits, recent_visit
    assert_not_includes today_visits, old_visit
  end

  test "tracks location information" do
    @visit.country = "US"
    @visit.region = "CA"
    @visit.city = "San Francisco"
    @visit.save!

    assert_equal "US", @visit.country
    assert_equal "CA", @visit.region
    assert_equal "San Francisco", @visit.city
  end

  test "tracks utm parameters" do
    @visit.utm_source = "google"
    @visit.utm_medium = "cpc"
    @visit.utm_campaign = "summer_sale"
    @visit.utm_term = "saas software"
    @visit.utm_content = "banner_ad"
    @visit.save!

    assert_equal "google", @visit.utm_source
    assert_equal "cpc", @visit.utm_medium
    assert_equal "summer_sale", @visit.utm_campaign
    assert_equal "saas software", @visit.utm_term
    assert_equal "banner_ad", @visit.utm_content
  end
end
