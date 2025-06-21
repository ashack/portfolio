require "test_helper"

class PlanSegmentTest < ActiveSupport::TestCase
  def setup
    @individual_plan = Plan.create!(
      name: "Individual Test Plan",
      plan_segment: "individual",
      amount_cents: 1000,
      active: true
    )

    @team_plan = Plan.create!(
      name: "Team Test Plan",
      plan_segment: "team",
      amount_cents: 5000,
      max_team_members: 10,
      active: true
    )

    @enterprise_plan = Plan.create!(
      name: "Enterprise Test Plan",
      plan_segment: "enterprise",
      amount_cents: 50000,
      max_team_members: 100,
      active: true
    )
  end

  test "plan segments are properly set" do
    assert @individual_plan.plan_segment_individual?
    assert @team_plan.plan_segment_team?
    assert @enterprise_plan.plan_segment_enterprise?
  end

  test "plan type must match segment for individual plans" do
    plan = Plan.new(
      name: "Invalid Plan",
      plan_segment: "individual",
      amount_cents: 1000
    )

    assert_not plan.valid?
    assert_includes plan.errors[:plan_segment], "must match plan_segment"
  end

  test "plan type must be team for team segment" do
    plan = Plan.new(
      name: "Invalid Plan",
      plan_segment: "team",
      amount_cents: 1000
    )

    assert_not plan.valid?
    assert_includes plan.errors[:plan_segment], "must match plan_segment"
  end

  test "plan type must be team for enterprise segment" do
    plan = Plan.new(
      name: "Invalid Plan",
      plan_segment: "enterprise",
      amount_cents: 1000
    )

    assert_not plan.valid?
    assert_includes plan.errors[:plan_segment], "must match plan_segment"
  end

  test "available_for_signup scope excludes enterprise plans" do
    available_plans = Plan.available_for_signup

    assert_includes available_plans, @individual_plan
    assert_includes available_plans, @team_plan
    assert_not_includes available_plans, @enterprise_plan
  end

  test "available_for_signup scope only includes active plans" do
    @individual_plan.update!(active: false)
    available_plans = Plan.available_for_signup

    assert_not_includes available_plans, @individual_plan
    assert_includes available_plans, @team_plan
  end

  test "by_segment scope filters correctly" do
    individual_plans = Plan.by_segment("individual")
    team_plans = Plan.by_segment("team")
    enterprise_plans = Plan.by_segment("enterprise")

    assert_includes individual_plans, @individual_plan
    assert_not_includes individual_plans, @team_plan
    assert_not_includes individual_plans, @enterprise_plan

    assert_not_includes team_plans, @individual_plan
    assert_includes team_plans, @team_plan
    assert_not_includes team_plans, @enterprise_plan

    assert_not_includes enterprise_plans, @individual_plan
    assert_not_includes enterprise_plans, @team_plan
    assert_includes enterprise_plans, @enterprise_plan
  end

  test "contact_sales_only? returns true only for enterprise plans" do
    assert_not @individual_plan.contact_sales_only?
    assert_not @team_plan.contact_sales_only?
    assert @enterprise_plan.contact_sales_only?
  end

  test "segment_display_name returns proper descriptions" do
    assert_equal "Direct user signup", @individual_plan.segment_display_name
    assert_equal "Team signup", @team_plan.segment_display_name
    assert_equal "Contact sales", @enterprise_plan.segment_display_name
  end
end
