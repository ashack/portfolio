require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    # Create test plans
    @free_plan = Plan.create!(
      name: "Individual Free",
      plan_segment: "individual",
      amount_cents: 0,
      features: [ "basic_dashboard", "email_support" ],
      active: true
    )

    @pro_plan = Plan.create!(
      name: "Individual Pro",
      plan_segment: "individual",
      stripe_price_id: "price_individual_pro",
      amount_cents: 1900,
      interval: "month",
      features: [ "basic_dashboard", "advanced_features", "priority_support" ],
      active: true
    )

    @team_plan = Plan.create!(
      name: "Team Plan",
      plan_segment: "team",
      amount_cents: 4900,
      interval: "month",
      max_team_members: 5,
      active: true
    )

    @inactive_plan = Plan.create!(
      name: "Inactive Plan",
      plan_segment: "individual",
      amount_cents: 999,
      active: false
    )
  end

  test "should get registration form with available plans" do
    get new_user_registration_path
    assert_response :success

    # Check that the form is displayed
    assert_select "h2", text: "Create your account"
    assert_select "form[action=?]", user_registration_path

    # Check that plan selection is shown
    assert_select "h3", text: "Choose Your Plan"

    # Only active individual plans should be shown
    assert_match @free_plan.name, response.body
    assert_match @pro_plan.name, response.body
    assert_no_match @team_plan.name, response.body
    assert_no_match @inactive_plan.name, response.body
  end

  test "should register new user with selected plan" do
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          first_name: "John",
          last_name: "Doe",
          email: "john@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          plan_id: @pro_plan.id
        }
      }
    end

    # Should redirect to dashboard after successful registration
    assert_redirected_to user_dashboard_path

    # Check the created user
    user = User.last
    assert_equal "john@example.com", user.email
    assert_equal "John", user.first_name
    assert_equal "Doe", user.last_name
    assert_equal "direct", user.user_type
    assert_equal "active", user.status
    assert_equal @pro_plan, user.plan
  end

  test "should register new user with free plan by default" do
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          first_name: "Jane",
          last_name: "Smith",
          email: "jane@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          plan_id: @free_plan.id
        }
      }
    end

    user = User.last
    assert_equal @free_plan, user.plan
  end

  test "should not allow registration with team plan" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          first_name: "Invalid",
          last_name: "User",
          email: "invalid@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          plan_id: @team_plan.id
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "must be a valid individual plan", response.body
  end

  test "should not allow registration with inactive plan" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          first_name: "Invalid",
          last_name: "User",
          email: "invalid2@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          plan_id: @inactive_plan.id
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "must be a valid individual plan", response.body
  end

  test "should not allow registration with invalid plan id" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          first_name: "Invalid",
          last_name: "User",
          email: "invalid3@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          plan_id: 999999
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "must be a valid individual plan", response.body
  end

  test "should enforce strong password requirements" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          first_name: "Weak",
          last_name: "Password",
          email: "weak@example.com",
          password: "password",
          password_confirmation: "password",
          plan_id: @free_plan.id
        }
      }
    end

    assert_response :unprocessable_entity
    # Should show password validation errors
    assert_select "div#error_explanation"
  end

  test "should validate email uniqueness" do
    # Create existing user
    existing_user = User.create!(
      email: "existing@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active"
    )

    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          first_name: "Duplicate",
          last_name: "Email",
          email: "existing@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          plan_id: @free_plan.id
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "is already taken", response.body
  end

  test "registration form should show plan features" do
    get new_user_registration_path
    assert_response :success

    # Check that features are displayed
    assert_match "basic_dashboard", response.body
    assert_match "email_support", response.body
    assert_match "advanced_features", response.body
    assert_match "priority_support", response.body
  end

  test "registration form should show plan pricing" do
    get new_user_registration_path
    assert_response :success

    # Check free plan
    assert_match "Free", response.body

    # Check pro plan pricing
    assert_match "$19", response.body
    assert_match "/month", response.body
  end

  test "newly registered users should be direct type" do
    post user_registration_path, params: {
      user: {
        first_name: "Direct",
        last_name: "User",
        email: "direct@example.com",
        password: "Password123!",
        password_confirmation: "Password123!",
        plan_id: @free_plan.id
      }
    }

    user = User.last
    assert user.direct?
    assert_not user.invited?
    assert_nil user.team_id
    assert_nil user.team_role
  end
end
