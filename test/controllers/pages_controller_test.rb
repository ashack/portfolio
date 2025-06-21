require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test plans
    @individual_free_plan = Plan.create!(
      name: "Individual Free",
      plan_segment: "individual",
      amount_cents: 0,
      features: [ "basic_dashboard", "email_support" ],
      active: true
    )

    @individual_pro_plan = Plan.create!(
      name: "Individual Pro",
      plan_segment: "individual",
      stripe_price_id: "price_individual_pro",
      amount_cents: 1900,
      interval: "month",
      features: [ "basic_dashboard", "advanced_features", "priority_support" ],
      active: true
    )

    @individual_inactive_plan = Plan.create!(
      name: "Individual Legacy",
      plan_segment: "individual",
      amount_cents: 999,
      features: [ "basic_dashboard" ],
      active: false
    )

    @team_starter_plan = Plan.create!(
      name: "Team Starter",
      plan_segment: "team",
      stripe_price_id: "price_team_starter",
      amount_cents: 4900,
      interval: "month",
      max_team_members: 5,
      features: [ "team_dashboard", "collaboration", "email_support" ],
      active: true
    )

    @team_pro_plan = Plan.create!(
      name: "Team Pro",
      plan_segment: "team",
      stripe_price_id: "price_team_pro",
      amount_cents: 9900,
      interval: "month",
      max_team_members: 15,
      features: [ "team_dashboard", "collaboration", "advanced_team_features", "priority_support" ],
      active: true
    )

    @team_inactive_plan = Plan.create!(
      name: "Team Legacy",
      plan_segment: "team",
      amount_cents: 2999,
      max_team_members: 10,
      features: [ "team_dashboard", "collaboration" ],
      active: false
    )
  end

  test "should get pricing without authentication" do
    get pricing_path
    assert_response :success
  end

  test "pricing page shows only active individual plans" do
    get pricing_path

    assert_response :success

    # Check that active individual plans are assigned
    assert_includes assigns(:individual_plans), @individual_free_plan
    assert_includes assigns(:individual_plans), @individual_pro_plan
    assert_not_includes assigns(:individual_plans), @individual_inactive_plan

    # Check content
    assert_match /pricing/i, response.body
  end

  test "pricing page shows only active team plans" do
    get pricing_path

    assert_response :success

    # Check that active team plans are assigned
    assert_includes assigns(:team_plans), @team_starter_plan
    assert_includes assigns(:team_plans), @team_pro_plan
    assert_not_includes assigns(:team_plans), @team_inactive_plan
  end

  test "pricing page works when signed in as direct user" do
    direct_user = sign_in_with(
      email: "directuser@example.com",
      user_type: "direct"
    )

    get pricing_path
    assert_response :success
  end

  test "pricing page works when signed in as team member" do
    team = Team.create!(
      name: "Test Team",
      admin: users(:super_admin),
      created_by: users(:super_admin)
    )

    team_member = sign_in_with(
      email: "teammember@example.com",
      user_type: "invited",
      team: team,
      team_role: "member"
    )

    get pricing_path
    assert_response :success
  end

  test "should get features without authentication" do
    get features_path
    assert_response :success
  end

  test "features page displays correctly" do
    get features_path

    assert_response :success
    assert_match /features/i, response.body
  end

  test "features page works when signed in" do
    sign_in_with(email: "user@example.com")

    get features_path
    assert_response :success
  end

  test "pricing action does not trigger authorization checks" do
    # This test ensures skip_after_action :verify_authorized works
    get pricing_path
    assert_response :success
  end

  test "features action does not trigger authorization checks" do
    # This test ensures skip_after_action :verify_authorized works
    get features_path
    assert_response :success
  end

  test "pricing page handles no plans gracefully" do
    # Delete all plans
    Plan.destroy_all

    get pricing_path
    assert_response :success

    assert_empty assigns(:individual_plans)
    assert_empty assigns(:team_plans)
  end
end
