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

  test "should be valid with valid attributes" do
    assert @plan.valid?
  end

  test "should require name" do
    @plan.name = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:name], "can't be blank"
  end

  test "should allow duplicate names" do
    @plan.save!

    duplicate_plan = @plan.dup
    assert duplicate_plan.valid?
  end

  test "should require plan_segment" do
    @plan.plan_segment = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:plan_segment], "can't be blank"
  end

  test "should only allow valid plan_segments" do
    @plan.plan_segment = "individual"
    assert @plan.valid?, "individual should be valid"

    @plan.plan_segment = "team"
    @plan.max_team_members = 5
    assert @plan.valid?, "team should be valid"

    assert_raises(ArgumentError) do
      @plan.plan_segment = "invalid"
    end
  end

  test "should only allow valid intervals" do
    valid_intervals = [ "month", "year", nil ]

    valid_intervals.each do |interval|
      @plan.interval = interval
      assert @plan.valid?, "#{interval.inspect} should be valid"
    end

    @plan.interval = "week"
    assert_not @plan.valid?
  end

  test "should allow nil stripe_price_id for free plans" do
    @plan.stripe_price_id = nil
    @plan.amount_cents = 0
    assert @plan.valid?
  end

  test "should default active to true" do
    new_plan = Plan.new
    assert_equal true, new_plan.active
  end

  test "should default amount_cents to 0" do
    new_plan = Plan.new
    assert_equal 0, new_plan.amount_cents
  end

  test "should validate amount_cents is not negative" do
    @plan.amount_cents = -100
    assert_not @plan.valid?
    assert_includes @plan.errors[:amount_cents], "must be greater than or equal to 0"
  end

  test "should require max_team_members for team plans" do
    @plan.plan_segment = "team"
    @plan.max_team_members = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:max_team_members], "is not a number"

    @plan.max_team_members = 0
    assert_not @plan.valid?
    assert_includes @plan.errors[:max_team_members], "must be greater than 0"

    @plan.max_team_members = 10
    assert @plan.valid?
  end

  test "should handle features as array" do
    @plan.features = [ "dashboard", "api_access", "support" ]
    @plan.save!
    @plan.reload

    assert_equal [ "dashboard", "api_access", "support" ], @plan.features
  end

  test "active scope returns only active plans" do
    @plan.save!

    inactive_plan = Plan.create!(
      name: "Inactive Plan",
      plan_segment: "individual",
      active: false
    )

    active_plans = Plan.active
    assert_includes active_plans, @plan
    assert_not_includes active_plans, inactive_plan
  end

  test "for_individuals scope returns only individual plans" do
    @plan.save!

    team_plan = Plan.create!(
      name: "Team Plan",
      plan_segment: "team",
      max_team_members: 5
    )

    individual_plans = Plan.for_individuals
    assert_includes individual_plans, @plan
    assert_not_includes individual_plans, team_plan
  end

  test "for_teams scope returns only team plans" do
    team_plan = Plan.create!(
      name: "Team Plan",
      plan_segment: "team",
      max_team_members: 5
    )

    individual_plan = Plan.create!(
      name: "Individual Plan",
      plan_segment: "individual"
    )

    team_plans = Plan.for_teams
    assert_includes team_plans, team_plan
    assert_not_includes team_plans, individual_plan
  end

  test "free? returns true for plans with 0 amount" do
    @plan.amount_cents = 0
    assert @plan.free?

    @plan.amount_cents = 100
    assert_not @plan.free?
  end

  test "formatted_price returns correct format" do
    @plan.amount_cents = 1999
    @plan.interval = "month"
    assert_equal "$19.99/month", @plan.formatted_price

    @plan.amount_cents = 0
    assert_equal "Free", @plan.formatted_price
  end

  test "has_feature? checks if feature exists" do
    @plan.features = [ "dashboard", "api_access", "support" ]
    @plan.save!

    assert @plan.has_feature?("dashboard")
    assert @plan.has_feature?("api_access")
    assert_not @plan.has_feature?("advanced_analytics")

    @plan.features = nil
    assert_not @plan.has_feature?("dashboard")
  end
end
