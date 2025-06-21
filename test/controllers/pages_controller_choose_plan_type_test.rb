require "test_helper"

class PagesControllerChoosePlanTypeTest < ActionDispatch::IntegrationTest
  def setup
    # Create some plans for each segment
    @individual_plan = Plan.create!(
      name: "Individual Pro",
      plan_segment: "individual",
      amount_cents: 1900,
      active: true
    )

    @team_plan = Plan.create!(
      name: "Team Starter",
      plan_segment: "team",
      amount_cents: 4900,
      max_team_members: 5,
      active: true
    )

    @enterprise_plan = Plan.create!(
      name: "Enterprise",
      plan_segment: "enterprise",
      amount_cents: 99900,
      max_team_members: 500,
      active: true
    )
  end

  test "can access choose plan type page" do
    get choose_plan_type_path
    assert_response :success
    assert_match /Choose Your Plan Type/, @response.body
  end

  test "shows all three plan segment options" do
    get choose_plan_type_path

    assert_match "Individual Plans", @response.body
    assert_match "Team Plans", @response.body
    assert_match "Need an Enterprise Solution?", @response.body
  end

  test "individual plan link goes to registration with correct segment" do
    get choose_plan_type_path

    assert_match "plan_segment=individual", @response.body
    assert_match "Choose Individual Plan", @response.body
  end

  test "team plan link goes to registration with correct segment" do
    get choose_plan_type_path

    assert_match "plan_segment=team", @response.body
    assert_match "Choose Team Plan", @response.body
  end

  test "enterprise plan shows contact sales message" do
    get choose_plan_type_path

    assert_match "Contact Sales", @response.body
    assert_match "custom features", @response.body
  end

  test "enterprise plan link exists" do
    get choose_plan_type_path

    # Check that there's a Contact Sales text in the page
    assert_match "Contact Sales", @response.body
  end
end
