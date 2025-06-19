require "test_helper"

class PlanValidationsTest < ActiveSupport::TestCase
  def setup
    @plan = Plan.new(
      name: "Test Plan",
      plan_type: "individual",
      amount_cents: 1999,
      interval: "month",
      features: [ "feature1", "feature2" ]
    )
  end

  # Name validation tests
  test "name presence validation" do
    @plan.name = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:name], "can't be blank"

    @plan.name = ""
    assert_not @plan.valid?
    assert_includes @plan.errors[:name], "can't be blank"
  end

  test "name can be duplicated" do
    @plan.save!

    duplicate = Plan.new(
      name: @plan.name,
      plan_type: "individual"
    )

    assert duplicate.valid?
  end

  # Plan type validation tests
  test "plan_type presence validation" do
    @plan.plan_type = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:plan_type], "can't be blank"
  end

  test "plan_type enum validation" do
    assert_equal 0, Plan.plan_types["individual"]
    assert_equal 1, Plan.plan_types["team"]

    assert_raises(ArgumentError) do
      @plan.plan_type = "invalid"
    end
  end

  # Amount validation tests
  test "amount_cents numericality validation" do
    @plan.amount_cents = "not a number"
    assert_not @plan.valid?
    assert_includes @plan.errors[:amount_cents], "is not a number"
  end

  test "amount_cents cannot be negative" do
    @plan.amount_cents = -1
    assert_not @plan.valid?
    assert_includes @plan.errors[:amount_cents], "must be greater than or equal to 0"

    @plan.amount_cents = -100
    assert_not @plan.valid?
    assert_includes @plan.errors[:amount_cents], "must be greater than or equal to 0"
  end

  test "amount_cents can be zero for free plans" do
    @plan.amount_cents = 0
    assert @plan.valid?
    assert @plan.free?
  end

  test "amount_cents can be large values" do
    @plan.amount_cents = 999999
    assert @plan.valid?
  end

  test "amount_cents defaults to 0" do
    new_plan = Plan.new
    assert_equal 0, new_plan.amount_cents
  end

  # Team-specific validation tests
  test "max_team_members required for team plans" do
    @plan.plan_type = "team"
    @plan.max_team_members = nil

    assert_not @plan.valid?
    assert_includes @plan.errors[:max_team_members], "is not a number"
  end

  test "max_team_members must be positive for team plans" do
    @plan.plan_type = "team"

    @plan.max_team_members = 0
    assert_not @plan.valid?
    assert_includes @plan.errors[:max_team_members], "must be greater than 0"

    @plan.max_team_members = -5
    assert_not @plan.valid?
    assert_includes @plan.errors[:max_team_members], "must be greater than 0"
  end

  test "max_team_members can be any positive number for team plans" do
    @plan.plan_type = "team"

    [ 1, 5, 10, 100, 1000 ].each do |count|
      @plan.max_team_members = count
      assert @plan.valid?, "max_team_members #{count} should be valid"
    end
  end

  test "max_team_members validation only runs for team plans" do
    @plan.plan_type = "individual"
    @plan.max_team_members = nil

    assert @plan.valid?
  end

  test "max_team_members validation uses conditional" do
    @plan.plan_type = "individual"
    @plan.max_team_members = 0  # Would be invalid for team

    assert @plan.valid?
  end

  # Interval validation tests
  test "interval can be nil" do
    @plan.interval = nil
    assert @plan.valid?
  end

  test "interval accepts month and year" do
    @plan.interval = "month"
    assert @plan.valid?

    @plan.interval = "year"
    assert @plan.valid?
  end

  test "interval rejects invalid values" do
    [ "day", "week", "quarter", "invalid" ].each do |interval|
      @plan.interval = interval
      assert_not @plan.valid?, "Interval '#{interval}' should be invalid"
      assert_includes @plan.errors[:interval], "is not included in the list"
    end
  end

  # Features tests
  test "features can be nil" do
    @plan.features = nil
    assert @plan.valid?
  end

  test "features can be empty array" do
    @plan.features = []
    assert @plan.valid?
  end

  test "features stores as array" do
    @plan.features = [ "dashboard", "api", "support" ]
    @plan.save!
    @plan.reload

    assert_equal [ "dashboard", "api", "support" ], @plan.features
    assert @plan.has_feature?("dashboard")
    assert @plan.has_feature?("api")
    assert_not @plan.has_feature?("advanced")
  end

  # Active flag tests
  test "active defaults to true" do
    new_plan = Plan.new
    assert_equal true, new_plan.active
  end

  test "active can be false" do
    @plan.active = false
    assert @plan.valid?
  end

  # Method tests
  test "free? method works correctly" do
    @plan.amount_cents = 0
    assert @plan.free?

    @plan.amount_cents = 1
    assert_not @plan.free?

    @plan.amount_cents = 100
    assert_not @plan.free?
  end

  test "formatted_price method" do
    @plan.amount_cents = 0
    assert_equal "Free", @plan.formatted_price

    @plan.amount_cents = 999
    @plan.interval = "month"
    assert_equal "$9.99/month", @plan.formatted_price

    @plan.amount_cents = 9999
    @plan.interval = "year"
    assert_equal "$99.99/year", @plan.formatted_price

    @plan.amount_cents = 100
    @plan.interval = nil
    assert_equal "$1.0/", @plan.formatted_price
  end

  test "has_feature? method" do
    @plan.features = [ "dashboard", "api_access", "24/7 support" ]

    assert @plan.has_feature?("dashboard")
    assert @plan.has_feature?("api_access")
    assert @plan.has_feature?("24/7 support")
    assert_not @plan.has_feature?("advanced_analytics")

    @plan.features = nil
    assert_not @plan.has_feature?("dashboard")

    @plan.features = []
    assert_not @plan.has_feature?("dashboard")
  end

  # Complex validation scenarios
  test "multiple validation errors" do
    @plan.name = nil
    @plan.plan_type = nil
    @plan.amount_cents = -100
    @plan.interval = "invalid"

    assert_not @plan.valid?

    assert @plan.errors[:name].any?
    assert @plan.errors[:plan_type].any?
    assert @plan.errors[:amount_cents].any?
    assert @plan.errors[:interval].any?
  end

  test "team plan with all required fields" do
    team_plan = Plan.new(
      name: "Team Pro",
      plan_type: "team",
      amount_cents: 9999,
      interval: "month",
      max_team_members: 10,
      features: [ "all features" ],
      active: true
    )

    assert team_plan.valid?
  end

  test "individual plan without team fields" do
    individual_plan = Plan.new(
      name: "Personal",
      plan_type: "individual",
      amount_cents: 499,
      interval: "month",
      features: [ "basic features" ],
      active: true
    )

    assert individual_plan.valid?
  end
end
