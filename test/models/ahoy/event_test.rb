require "test_helper"

class Ahoy::EventTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "event_user@example.com",
      password: "Password123!",
      first_name: "Event",
      last_name: "User"
    )
    @user.skip_confirmation!
    @user.save!

    @visit = Ahoy::Visit.create!(
      visit_token: SecureRandom.uuid,
      visitor_token: SecureRandom.uuid,
      user: @user,
      ip: "192.168.1.200",
      started_at: Time.current
    )

    @event = Ahoy::Event.new(
      visit: @visit,
      user: @user,
      name: "page_view",
      properties: {
        page: "/dashboard",
        title: "Dashboard",
        time_on_page: 45
      },
      time: Time.current
    )
  end

  test "should be valid with valid attributes" do
    assert @event.valid?
  end

  test "should require visit" do
    @event.visit = nil
    assert_not @event.valid?
    assert_includes @event.errors[:visit], "must exist"
  end

  test "should be valid without user" do
    @event.user = nil
    assert @event.valid?
  end

  test "belongs to visit association" do
    @event.save!
    assert_equal @visit, @event.visit
    assert_includes @visit.events, @event
  end

  test "belongs to user association" do
    @event.save!
    assert_equal @user, @event.user
  end

  test "serializes properties as JSON" do
    @event.save!
    @event.reload

    assert_equal "/dashboard", @event.properties["page"]
    assert_equal "Dashboard", @event.properties["title"]
    assert_equal 45, @event.properties["time_on_page"]
  end

  test "can store complex properties" do
    @event.properties = {
      user_info: {
        id: @user.id,
        role: @user.system_role
      },
      metadata: {
        browser: "Chrome",
        version: "120.0"
      },
      tags: [ "important", "conversion" ],
      timestamp: Time.current.to_i
    }

    @event.save!
    @event.reload

    assert_equal @user.id, @event.properties["user_info"]["id"]
    assert_equal @user.system_role, @event.properties["user_info"]["role"]
    assert_equal "Chrome", @event.properties["metadata"]["browser"]
    assert_equal [ "important", "conversion" ], @event.properties["tags"]
  end

  test "tracks different event types" do
    # Page view event
    page_view = Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "page_view",
      properties: { page: "/pricing" },
      time: Time.current
    )

    # Click event
    click_event = Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "button_click",
      properties: {
        button_id: "signup-btn",
        button_text: "Sign Up Now"
      },
      time: Time.current
    )

    # Form submission event
    form_event = Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "form_submit",
      properties: {
        form_id: "contact-form",
        fields: [ "name", "email", "message" ]
      },
      time: Time.current
    )

    assert_equal "page_view", page_view.name
    assert_equal "button_click", click_event.name
    assert_equal "form_submit", form_event.name
  end

  test "can track anonymous events" do
    anonymous_event = Ahoy::Event.new(
      visit: @visit,
      user: nil,
      name: "anonymous_action",
      properties: { action: "browse" },
      time: Time.current
    )

    assert anonymous_event.valid?
    assert anonymous_event.save
    assert_nil anonymous_event.user
  end

  test "can query events by name" do
    @event.save!

    # Create different types of events
    Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "button_click",
      properties: { button: "save" },
      time: Time.current
    )

    Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "page_view",
      properties: { page: "/profile" },
      time: Time.current
    )

    page_views = Ahoy::Event.where(name: "page_view")
    assert_equal 2, page_views.count

    clicks = Ahoy::Event.where(name: "button_click")
    assert_equal 1, clicks.count
  end

  test "can query events by time range" do
    # Create events at different times
    old_event = Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "old_event",
      properties: {},
      time: 2.days.ago
    )

    recent_event = Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "recent_event",
      properties: {},
      time: 1.hour.ago
    )

    today_events = Ahoy::Event.where("time >= ?", Date.current.beginning_of_day)
    assert_includes today_events, recent_event
    assert_not_includes today_events, old_event
  end

  test "can track custom metrics in properties" do
    @event.name = "purchase"
    @event.properties = {
      product_id: 123,
      product_name: "Premium Plan",
      amount: 99.99,
      currency: "USD",
      quantity: 1,
      discount_applied: true,
      discount_amount: 10.00,
      final_amount: 89.99
    }

    @event.save!
    @event.reload

    assert_equal 123, @event.properties["product_id"]
    assert_equal 99.99, @event.properties["amount"]
    assert_equal true, @event.properties["discount_applied"]
    assert_equal 89.99, @event.properties["final_amount"]
  end

  test "tracks event sequence within a visit" do
    # Create a sequence of events
    events = []

    events << Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "page_view",
      properties: { page: "/", step: 1 },
      time: 5.minutes.ago
    )

    events << Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "page_view",
      properties: { page: "/features", step: 2 },
      time: 4.minutes.ago
    )

    events << Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "button_click",
      properties: { button: "start_trial", step: 3 },
      time: 3.minutes.ago
    )

    events << Ahoy::Event.create!(
      visit: @visit,
      user: @user,
      name: "form_submit",
      properties: { form: "signup", step: 4 },
      time: 2.minutes.ago
    )

    # Query events in order
    visit_events = @visit.events.order(:time)

    assert_equal 4, visit_events.count
    assert_equal "/", visit_events.first.properties["page"]
    assert_equal "signup", visit_events.last.properties["form"]
  end
end
