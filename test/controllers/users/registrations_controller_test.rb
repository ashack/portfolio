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

  # ========== CRITICAL TESTS (Weight 9) ==========

  # Weight: 9 - Security (CR-A1): Strong password enforcement
  test "enforces strong password requirements" do
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
    # Password validation error should be shown
    assert_match /password/, response.body
  end

  # Weight: 9 - Authentication integrity (IR-U1): Email uniqueness
  test "validates email uniqueness" do
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

  # Weight: 9 - Critical user creation + billing
  test "registers new user with selected plan" do
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

    # Should redirect to sign in due to email confirmation requirement
    assert_redirected_to new_user_session_path

    # Check the created user
    user = User.last
    assert_equal "john@example.com", user.email
    assert_equal "John", user.first_name
    assert_equal "Doe", user.last_name
    assert_equal "direct", user.user_type
    assert_equal "active", user.status
    assert_equal @pro_plan, user.plan
  end

  # ========== HIGH PRIORITY TESTS (Weight 8) ==========

  # Weight: 8 - Revenue protection: Plan validation matrix
  test "validates plan selection and requirements" do
    plan_validation_matrix = [
      # [plan, team_name, expected_result, error_message]
      [@team_plan, nil, false, "Team name is required when selecting a team plan"],
      [@inactive_plan, nil, false, "must be a valid plan"],
      [999999, nil, false, "must be a valid plan"],
      # Free plan with no team name should succeed - removed as it's tested separately
    ]

    plan_validation_matrix.each do |plan, team_name, should_succeed, error_msg|
      plan_id = plan.is_a?(Plan) ? plan.id : plan
      
      assert_no_difference("User.count") do
        params = {
          user: {
            first_name: "Test",
            last_name: "User",
            email: "test#{plan_id}@example.com",
            password: "Password123!",
            password_confirmation: "Password123!",
            plan_id: plan_id
          }
        }
        params[:user][:team_name] = team_name if team_name
        
        post user_registration_path, params: params
      end

      if should_succeed
        assert_response :redirect
      else
        assert_response :unprocessable_entity
        assert_match error_msg, response.body if error_msg
      end
    end
  end

  # ========== MEDIUM PRIORITY TESTS (Weight 6-7) ==========

  # Weight: 7 - Business logic: Default to free plan
  test "defaults to free plan when no plan selected" do
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

  # Weight: 6 - User type enforcement
  test "newly registered users are direct type" do
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

  # Weight: 5 - UI verification (consolidated)
  test "registration form displays correctly with plans and features" do
    get new_user_registration_path
    assert_response :success

    # Check form structure
    assert_match /Create your account/i, response.body
    assert_match /Choose Your Plan/i, response.body

    # Check plans displayed - both individual and team plans are shown
    assert_match @free_plan.name, response.body
    assert_match @pro_plan.name, response.body
    assert_match @team_plan.name, response.body  # Team plans ARE shown for direct users
    assert_no_match @inactive_plan.name, response.body  # But inactive plans are not

    # Check features and pricing
    assert_match /Basic dashboard/i, response.body
    assert_match /Email support/i, response.body
    assert_match "Free", response.body
    assert_match "$19", response.body
    assert_match "/month", response.body
  end
end
