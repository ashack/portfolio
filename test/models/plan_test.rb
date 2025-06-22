require "test_helper"

class PlanTest < ActiveSupport::TestCase
  def setup
    @plan = Plan.new(
      name: "Test Plan",
      plan_segment: "individual",
      stripe_price_id: "price_test123",
      amount_cents: 1999,
      interval: "month",
      features: [ "feature1", "feature2" ],
      active: true
    )
  end

  # ========================================================================
  # HIGH PRIORITY TESTS (Weight: 7-8)
  # ========================================================================

  # Weight: 8 - CR-B3: Plan segmentation - billing separation
  test "plan segmentation enforces billing separation" do
    # Test all valid segments
    segments = {
      "individual" => { max_team_members: nil },
      "team" => { max_team_members: 5 },
      "enterprise" => { max_team_members: nil }
    }

    segments.each do |segment, attrs|
      @plan.plan_segment = segment
      @plan.max_team_members = attrs[:max_team_members]
      assert @plan.valid?, "Segment '#{segment}' should be valid"
    end

    # Invalid segment raises error
    assert_raises(ArgumentError) do
      @plan.plan_segment = "invalid"
    end
  end

  # Weight: 8 - CR-T2: Member limit validation - team limits
  test "team plans enforce member limit requirements" do
    @plan.plan_segment = "team"

    # Must have max_team_members
    @plan.max_team_members = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:max_team_members], "is not a number"

    # Must be positive
    @plan.max_team_members = 0
    assert_not @plan.valid?
    assert_includes @plan.errors[:max_team_members], "must be greater than 0"

    @plan.max_team_members = -5
    assert_not @plan.valid?
    assert_includes @plan.errors[:max_team_members], "must be greater than 0"

    # Valid with positive number
    @plan.max_team_members = 10
    assert @plan.valid?

    # Non-team plans don't require max_team_members
    @plan.plan_segment = "individual"
    @plan.max_team_members = nil
    assert @plan.valid?
  end

  # Weight: 7 - IR-B2: Free plan detection - pricing logic
  test "free plan detection and pricing" do
    # Free plan
    @plan.amount_cents = 0
    assert @plan.free?
    assert_equal "Free", @plan.formatted_price

    # Paid plans
    @plan.amount_cents = 1999
    @plan.interval = "month"
    assert_not @plan.free?
    assert_equal "$19.99/month", @plan.formatted_price

    @plan.amount_cents = 9999
    @plan.interval = "year"
    assert_equal "$99.99/year", @plan.formatted_price

    # Edge case: no interval
    @plan.amount_cents = 100
    @plan.interval = nil
    assert_equal "$1.0/", @plan.formatted_price
  end

  # Weight: 7 - IR-B3: Enterprise contact sales - sales process
  test "enterprise plans require contact sales" do
    @plan.plan_segment = "enterprise"
    @plan.save!

    assert @plan.contact_sales?
    assert @plan.contact_sales_only?

    # Non-enterprise plans allow direct signup
    [ "individual", "team" ].each do |segment|
      @plan.plan_segment = segment
      @plan.max_team_members = 5 if segment == "team"
      assert_not @plan.contact_sales?
      assert_not @plan.contact_sales_only?
    end
  end

  # ========================================================================
  # MEDIUM PRIORITY TESTS (Weight: 5-6)
  # ========================================================================

  # Weight: 6 - IR-B4: Feature checking - feature access
  test "feature management works correctly" do
    @plan.features = [ "dashboard", "api_access", "support" ]
    @plan.save!
    @plan.reload

    # Check feature exists
    assert @plan.has_feature?("dashboard")
    assert @plan.has_feature?("api_access")
    assert_not @plan.has_feature?("advanced_analytics")

    # Handle edge cases
    @plan.features = nil
    assert_not @plan.has_feature?("dashboard")

    @plan.features = []
    assert_not @plan.has_feature?("dashboard")
  end

  # Weight: 6 - Standard validations (consolidated)
  test "field validations work correctly" do
    # Name validation
    @plan.name = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:name], "can't be blank"

    # Plan segment validation
    @plan.name = "Valid Name"
    @plan.plan_segment = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:plan_segment], "can't be blank"

    # Amount validation
    @plan.plan_segment = "individual"
    @plan.amount_cents = -1
    assert_not @plan.valid?
    assert_includes @plan.errors[:amount_cents], "must be greater than or equal to 0"

    # Interval validation
    @plan.amount_cents = 1000
    @plan.interval = "invalid"
    assert_not @plan.valid?
    assert_includes @plan.errors[:interval], "is not included in the list"

    # Valid with all correct values
    @plan.interval = "month"
    assert @plan.valid?
  end

  # Weight: 5 - Query scopes (consolidated)
  test "scopes filter plans correctly" do
    # Create test plans
    individual_plan = @plan
    individual_plan.save!

    team_plan = Plan.create!(
      name: "Team Plan",
      plan_segment: "team",
      max_team_members: 5,
      active: true
    )

    enterprise_plan = Plan.create!(
      name: "Enterprise Plan",
      plan_segment: "enterprise",
      active: true
    )

    inactive_plan = Plan.create!(
      name: "Inactive Plan",
      plan_segment: "individual",
      active: false
    )

    # Test active scope
    active_plans = Plan.active
    assert_includes active_plans, individual_plan
    assert_includes active_plans, team_plan
    assert_not_includes active_plans, inactive_plan

    # Test segment-specific scopes
    assert_includes Plan.for_individuals, individual_plan
    assert_not_includes Plan.for_individuals, team_plan

    assert_includes Plan.for_teams, team_plan
    assert_not_includes Plan.for_teams, individual_plan

    assert_includes Plan.for_enterprise, enterprise_plan
    assert_not_includes Plan.for_enterprise, individual_plan

    # Test available_for_signup scope - excludes enterprise and inactive
    available = Plan.available_for_signup
    assert_includes available, individual_plan
    assert_includes available, team_plan
    assert_not_includes available, enterprise_plan
    assert_not_includes available, inactive_plan
  end

  # ========================================================================
  # LOW PRIORITY TESTS (Keep only essential)
  # ========================================================================

  # Weight: 4 - Keep one test for display methods
  test "display methods format plan information correctly" do
    # Segment display names
    display_names = {
      "individual" => [ "Direct user signup", "Individual" ],
      "team" => [ "Team signup", "Team" ],
      "enterprise" => [ "Contact sales", "Enterprise (Contact Sales)" ]
    }

    display_names.each do |segment, (segment_name, display_name)|
      @plan.plan_segment = segment
      assert_equal segment_name, @plan.segment_display_name
      assert_equal display_name, @plan.display_segment
    end
  end
end
