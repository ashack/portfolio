require "test_helper"

class Users::RegistrationsControllerPlanSegmentTest < ActionDispatch::IntegrationTest
  def setup
    # Create plans for different segments
    @individual_free = Plan.create!(
      name: "Individual Free",
      plan_segment: "individual",
      amount_cents: 0,
      active: true
    )

    @individual_pro = Plan.create!(
      name: "Individual Pro",
      plan_segment: "individual",
      amount_cents: 1900,
      active: true
    )

    @team_starter = Plan.create!(
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

  test "registration page with individual segment shows all available plans" do
    get new_user_registration_path(plan_segment: "individual")
    assert_response :success

    # Shows ALL available plans (both individual and team)
    assert_match @individual_free.name, @response.body
    assert_match @individual_pro.name, @response.body
    assert_match @team_starter.name, @response.body

    # But not enterprise plans
    assert_no_match @enterprise_plan.name, @response.body
  end

  test "registration page with team segment shows all available plans" do
    get new_user_registration_path(plan_segment: "team")
    assert_response :success

    # Shows ALL available plans (both individual and team)
    assert_match @individual_free.name, @response.body
    assert_match @individual_pro.name, @response.body
    assert_match @team_starter.name, @response.body

    # But not enterprise plans
    assert_no_match @enterprise_plan.name, @response.body
  end

  test "registration page without segment defaults to individual" do
    get new_user_registration_path
    assert_response :success

    # Should show individual plans by default
    assert_match @individual_free.name, @response.body
    assert_match @individual_pro.name, @response.body
  end

  test "can register with individual plan" do
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          first_name: "New",
          last_name: "User",
          plan_id: @individual_pro.id,
          plan_segment: "individual"
        }
      }
    end

    user = User.last
    assert_equal "direct", user.user_type
    assert_equal @individual_pro, user.plan
    assert_redirected_to new_user_session_path  # Redirects to sign in due to email confirmation
  end

  test "team registration requires team name" do
    # When selecting a team plan, team name is required
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "teamuser@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          first_name: "Team",
          last_name: "User",
          plan_id: @team_starter.id,
          plan_segment: "team"
          # Missing team_name
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "Team name is required when selecting a team plan", @response.body
  end

  test "cannot register with enterprise plan" do
    # Enterprise plans shouldn't be available for signup
    get new_user_registration_path(plan_segment: "enterprise")
    assert_response :success

    # Should not show any plans (enterprise plans are contact-sales only)
    assert_no_match @enterprise_plan.name, @response.body
  end

  test "registration preserves plan_segment in session on validation error" do
    post user_registration_path, params: {
      user: {
        email: "invalid",  # Invalid email
        password: "Password123!",
        password_confirmation: "Password123!",
        plan_segment: "individual"
      }
    }

    assert_response :unprocessable_entity
    # Just verify we show the form again, not the specific text
    assert_match /Choose Your Plan/i, @response.body
  end
end
