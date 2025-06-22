require "test_helper"

class Admin::Super::PlansControllerTest < ActionDispatch::IntegrationTest
  def setup
    @super_admin = sign_in_with(
      email: "super@example.com",
      system_role: "super_admin"
    )

    @plan = Plan.create!(
      name: "Test Plan",
      plan_segment: "individual",
      amount_cents: 999,
      interval: "month",
      features: [ "feature1", "feature2" ],
      active: true
    )
  end

  test "should get index as super admin" do
    get admin_super_plans_path
    assert_response :success
    assert_match "Plans Management", response.body
  end

  test "should not get index as site admin" do
    sign_out @super_admin
    sign_in_with(
      email: "site@example.com",
      system_role: "site_admin"
    )

    get admin_super_plans_path
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal "You must be a super admin to access this area.", flash[:alert]
  end

  test "should not get index as regular user" do
    sign_out @super_admin
    sign_in_with(email: "user@example.com")

    get admin_super_plans_path
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal "You must be a super admin to access this area.", flash[:alert]
  end

  test "should get new" do
    get new_admin_super_plan_path
    assert_response :success
    assert_match "New Plan", response.body
  end

  test "should create plan" do
    assert_difference("Plan.count") do
      post admin_super_plans_path, params: {
        plan: {
          name: "New Plan",
          plan_segment: "team",
          stripe_price_id: "price_new",
          amount_cents: 4999,
          interval: "month",
          max_team_members: 10,
          features: [ "feature1", "feature2", "feature3" ],
          active: true
        }
      }
    end

    assert_redirected_to admin_super_plans_path
    assert_equal "Plan was successfully created.", flash[:notice]

    plan = Plan.last
    assert_equal "New Plan", plan.name
    assert_equal "team", plan.plan_segment
    assert_equal 4999, plan.amount_cents
    assert_equal 10, plan.max_team_members
    assert_equal [ "feature1", "feature2", "feature3" ], plan.features
  end

  test "should show plan" do
    get admin_super_plan_path(@plan)
    assert_response :success
    assert_match @plan.name, response.body
  end

  test "should get edit" do
    get edit_admin_super_plan_path(@plan)
    assert_response :success
    assert_match "Edit Plan", response.body
  end

  test "should update plan" do
    patch admin_super_plan_path(@plan), params: {
      plan: {
        name: "Updated Plan",
        amount_cents: 1999,
        features: [ "new_feature1", "new_feature2" ]
      }
    }

    assert_redirected_to admin_super_plans_path
    assert_equal "Plan was successfully updated.", flash[:notice]

    @plan.reload
    assert_equal "Updated Plan", @plan.name
    assert_equal 1999, @plan.amount_cents
    assert_equal [ "new_feature1", "new_feature2" ], @plan.features
  end

  test "should destroy plan" do
    assert_difference("Plan.count", -1) do
      delete admin_super_plan_path(@plan)
    end

    assert_redirected_to admin_super_plans_path
    assert_equal "Plan was successfully deleted.", flash[:notice]
  end

  test "should handle invalid plan params" do
    post admin_super_plans_path, params: {
      plan: {
        name: "", # Invalid - blank name
        plan_segment: "individual"
      }
    }

    assert_response :unprocessable_entity
    assert_match /error/i, response.body
  end

  test "should display correct form fields for team plan" do
    get new_admin_super_plan_path
    assert_response :success

    # Check that team-specific fields are present in the form
    assert_match "max_team_members", response.body
    assert_match "team-specific-fields", response.body
  end

  test "should display correct form fields for individual plan" do
    get edit_admin_super_plan_path(@plan)
    assert_response :success

    # For individual plan, team fields should be hidden by default
    assert_match "team-specific-fields", response.body
    assert_match "hidden", response.body
  end

  test "plan index should show all plans" do
    # Create additional plans
    Plan.create!(
      name: "Team Plan",
      plan_segment: "team",
      amount_cents: 9999,
      max_team_members: 20,
      active: true
    )

    Plan.create!(
      name: "Inactive Plan",
      plan_segment: "individual",
      amount_cents: 0,
      active: false
    )

    get admin_super_plans_path
    assert_response :success

    # Check that plans are displayed (we have fixtures plus test plans)
    assert Plan.count >= 3
    assert_match "Test Plan", response.body
    assert_match "Team Plan", response.body
    assert_match "Inactive Plan", response.body
  end

  test "should authorize all actions through policy" do
    # This test ensures that all actions use Pundit authorization
    # by checking that non-super admins are rejected

    sign_out @super_admin
    site_admin = sign_in_with(
      email: "siteadmin@example.com",
      system_role: "site_admin"
    )

    # Test each action
    get admin_super_plans_path
    assert_response :redirect

    get new_admin_super_plan_path
    assert_response :redirect

    post admin_super_plans_path, params: { plan: { name: "Test" } }
    assert_response :redirect

    get admin_super_plan_path(@plan)
    assert_response :redirect

    get edit_admin_super_plan_path(@plan)
    assert_response :redirect

    patch admin_super_plan_path(@plan), params: { plan: { name: "Test" } }
    assert_response :redirect

    delete admin_super_plan_path(@plan)
    assert_response :redirect
  end
end
