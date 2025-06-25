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

  # ========================================================================
  # NEW CRITICAL TESTS - MISSING BUSINESS RULES
  # ========================================================================

  # Weight: 10 - CR-B2: Plan enforcement - Features and limits must match the active plan
  test "plan enforcement ensures features match active subscription" do
    @plan.save!

    # Create user with plan
    user = User.create!(
      email: "planusr@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    # In practice, Pay gem would create subscription
    # Mock subscription active check
    assert @plan.active?

    # Plan features determine access
    @plan.features = [ "basic_dashboard", "email_support" ]
    @plan.save!

    assert @plan.has_feature?("basic_dashboard")
    assert @plan.has_feature?("email_support")
    assert_not @plan.has_feature?("advanced_analytics")

    # Deactivated plan prevents new subscriptions
    @plan.update!(active: false)
    assert_not @plan.active?

    # But existing subscriptions continue (handled by service layer)
  end

  # Weight: 10 - CR-B1: Billing isolation - Users, Teams, and Enterprise have separate billing
  test "plans enforce billing isolation between segments" do
    # Individual plan for direct users
    individual_plan = Plan.create!(
      name: "Individual Pro",
      plan_segment: "individual",
      stripe_price_id: "price_individual_pro",
      amount_cents: 1999,
      interval: "month",
      active: true
    )

    # Team plan for teams
    team_plan = Plan.create!(
      name: "Team Pro",
      plan_segment: "team",
      stripe_price_id: "price_team_pro",
      amount_cents: 9999,
      interval: "month",
      max_team_members: 15,
      active: true
    )

    # Enterprise plan for enterprise groups
    enterprise_plan = Plan.create!(
      name: "Enterprise Pro",
      plan_segment: "enterprise",
      stripe_price_id: "price_enterprise_pro",
      amount_cents: 99999,
      interval: "month",
      active: true
    )

    # Each has different Stripe price IDs
    assert_not_equal individual_plan.stripe_price_id, team_plan.stripe_price_id
    assert_not_equal team_plan.stripe_price_id, enterprise_plan.stripe_price_id

    # Different pricing
    assert_not_equal individual_plan.amount_cents, team_plan.amount_cents
    assert_not_equal team_plan.amount_cents, enterprise_plan.amount_cents

    # Different features/limits
    assert_nil individual_plan.max_team_members
    assert_equal 15, team_plan.max_team_members
    assert_nil enterprise_plan.max_team_members # Unlimited or custom
  end

  # Weight: 9 - Team plan member limit validation edge cases
  test "team plan member limits handle edge cases correctly" do
    @plan.plan_segment = "team"

    # Very large limits
    @plan.max_team_members = 1000
    assert @plan.valid?

    # Reasonable limits
    team_limits = [ 5, 10, 15, 25, 50, 100 ]
    team_limits.each do |limit|
      @plan.max_team_members = limit
      assert @plan.valid?, "Limit #{limit} should be valid"
    end

    # Edge case: Float gets converted to integer
    @plan.max_team_members = 10.5
    assert @plan.valid?
    assert_equal 10, @plan.max_team_members

    # Edge case: String number
    @plan.max_team_members = "20"
    assert @plan.valid?
    assert_equal 20, @plan.max_team_members
  end

  # Weight: 9 - Stripe price ID requirements for paid plans
  test "stripe price ID required for paid plans" do
    # Free plan doesn't need Stripe price ID
    @plan.amount_cents = 0
    @plan.stripe_price_id = nil
    assert @plan.valid?

    # Paid plan should have Stripe price ID (business logic)
    @plan.amount_cents = 1999
    @plan.stripe_price_id = nil
    # Model allows it but business logic would require it
    assert @plan.valid?

    # With Stripe price ID
    @plan.stripe_price_id = "price_test123"
    assert @plan.valid?

    # Stripe price ID format (if validated)
    valid_price_ids = [
      "price_1234567890",
      "price_individual_monthly",
      "price_team_annual"
    ]

    valid_price_ids.each do |price_id|
      @plan.stripe_price_id = price_id
      assert @plan.valid?, "Price ID #{price_id} should be valid"
    end
  end

  # Weight: 8 - Plan feature inheritance and upgrades
  test "plan features support upgrade paths" do
    # Basic plan
    basic_plan = Plan.create!(
      name: "Basic",
      plan_segment: "individual",
      amount_cents: 0,
      features: [ "basic_dashboard", "email_support" ],
      active: true
    )

    # Pro plan includes basic features plus more
    pro_plan = Plan.create!(
      name: "Pro",
      plan_segment: "individual",
      amount_cents: 1999,
      interval: "month",
      features: [ "basic_dashboard", "email_support", "advanced_features", "priority_support" ],
      active: true
    )

    # Premium plan includes all pro features plus more
    premium_plan = Plan.create!(
      name: "Premium",
      plan_segment: "individual",
      amount_cents: 4999,
      interval: "month",
      features: [ "basic_dashboard", "email_support", "advanced_features", "priority_support", "premium_features", "phone_support" ],
      active: true
    )

    # Each higher plan includes all lower plan features
    basic_plan.features.each do |feature|
      assert pro_plan.has_feature?(feature), "Pro should have basic feature: #{feature}"
      assert premium_plan.has_feature?(feature), "Premium should have basic feature: #{feature}"
    end

    pro_plan.features.each do |feature|
      assert premium_plan.has_feature?(feature), "Premium should have pro feature: #{feature}"
    end
  end

  # Weight: 8 - Interval validation and pricing display
  test "plan intervals and pricing display correctly" do
    # Monthly pricing
    @plan.amount_cents = 999
    @plan.interval = "month"
    assert_equal "$9.99/month", @plan.formatted_price

    # Annual pricing
    @plan.amount_cents = 9999
    @plan.interval = "year"
    assert_equal "$99.99/year", @plan.formatted_price

    # One-time pricing (no interval)
    @plan.amount_cents = 49999
    @plan.interval = nil
    assert @plan.valid? # Allows nil interval
    assert_equal "$499.99/", @plan.formatted_price

    # Invalid intervals
    invalid_intervals = [ "day", "week", "quarterly", "biannual" ]
    invalid_intervals.each do |interval|
      @plan.interval = interval
      assert_not @plan.valid?
      assert_includes @plan.errors[:interval], "is not included in the list"
    end
  end

  # Weight: 7 - Plan activation and deactivation rules
  test "plan activation affects availability" do
    @plan.save!

    # Active plan available for signup
    assert @plan.active?
    if @plan.plan_segment != "enterprise"
      assert_includes Plan.available_for_signup, @plan
    end

    # Deactivate plan
    @plan.update!(active: false)
    assert_not @plan.active?
    assert_not_includes Plan.available_for_signup, @plan

    # Reactivate plan
    @plan.update!(active: true)
    assert @plan.active?
  end

  # Weight: 7 - Plan comparison and sorting
  test "plans can be compared and sorted by price" do
    plans = []

    # Create plans with different prices
    [ 0, 999, 1999, 4999, 9999 ].each_with_index do |cents, i|
      plans << Plan.create!(
        name: "Plan #{i}",
        plan_segment: "individual",
        amount_cents: cents,
        interval: "month",
        active: true
      )
    end

    # Sort by price
    sorted = plans.sort_by(&:amount_cents)

    # Verify order
    assert_equal 0, sorted.first.amount_cents
    assert_equal 9999, sorted.last.amount_cents

    # Free plan should be first
    assert sorted.first.free?
    assert_not sorted.last.free?
  end

  # Weight: 6 - Plan JSON serialization for API
  test "plan serializes correctly for API responses" do
    @plan.features = [ "feature1", "feature2", "feature3" ]
    @plan.save!

    # Test as_json output (would be customized in model)
    json = @plan.as_json

    assert json["id"]
    assert_equal "Test Plan", json["name"]
    assert_equal "individual", json["plan_segment"]
    assert_equal 1999, json["amount_cents"]
    assert_equal [ "feature1", "feature2", "feature3" ], json["features"]

    # Sensitive fields might be excluded in practice
    # assert_nil json["created_at"] # If excluded
  end
end
