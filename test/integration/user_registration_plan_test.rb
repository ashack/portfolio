require "test_helper"

class UserRegistrationPlanTest < ActionDispatch::IntegrationTest
  def setup
    # Create test plans
    @free_plan = Plan.create!(
      name: "Test Free",
      plan_segment: "individual",
      amount_cents: 0,
      active: true
    )

    @pro_plan = Plan.create!(
      name: "Test Pro",
      plan_segment: "individual",
      amount_cents: 1900,
      active: true
    )
  end

  test "user registration assigns selected plan" do
    # Register with pro plan selected
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          email: "testplan@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          first_name: "Test",
          last_name: "User",
          plan_id: @pro_plan.id,
          plan_segment: "individual"
        }
      }
    end

    # Check the user was created with correct plan
    user = User.find_by(email: "testplan@example.com")
    assert_not_nil user
    assert_equal @pro_plan.id, user.plan_id
    assert_equal "Test Pro", user.plan.name
    assert_equal "direct", user.user_type
    assert_equal "active", user.status
  end

  test "user registration defaults to free plan when no plan selected" do
    # Register without plan_id
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          email: "testfree@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          first_name: "Test",
          last_name: "Free",
          plan_segment: "individual"
        }
      }
    end

    # Check the user was created with free plan
    user = User.find_by(email: "testfree@example.com")
    assert_not_nil user
    assert_not_nil user.plan
    assert_equal 0, user.plan.amount_cents
    assert_equal "individual", user.plan.plan_segment
  end
end
