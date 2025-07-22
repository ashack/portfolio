require "test_helper"

class OnboardingFlowTest < ActionDispatch::IntegrationTest
  def setup
    @new_user_params = {
      email: "newuser#{Time.now.to_i}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      first_name: "New",
      last_name: "User"
    }
  end

  test "direct user registration without plan selection" do
    # Visit registration page
    get new_user_registration_path
    assert_response :success
    
    # Ensure plan selection is not present
    assert_select "[data-plan-type]", count: 0
    
    # Register new user
    assert_difference 'User.count', 1 do
      post user_registration_path, params: { user: @new_user_params }
    end
    
    # User should be created without a plan
    user = User.find_by(email: @new_user_params[:email])
    assert_nil user.plan_id, "New user should not have a plan assigned"
    assert_equal false, user.onboarding_completed, "Onboarding should not be completed"
    assert_equal "welcome", user.onboarding_step, "Onboarding step should be 'welcome'"
  end

  test "confirmed user is redirected to onboarding on first sign in" do
    # Create and confirm a user without a plan
    user = User.create!(
      email: "onboarding_test#{Time.now.to_i}@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current,
      first_name: "Test",
      last_name: "User",
      onboarding_completed: false,
      plan_id: nil
    )
    
    # Sign in
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "Password123!"
      }
    }
    
    # Should redirect to onboarding
    assert_redirected_to users_onboarding_path
    follow_redirect!
    
    # Should show welcome page
    assert_response :success
    assert_select "h1", text: /Welcome to.*Test/
    assert_select "a[href=?]", plan_selection_users_onboarding_path, text: /Continue to Plan Selection/
  end

  test "onboarding flow from welcome to plan selection" do
    # Create user and sign in
    user = User.create!(
      email: "flow_test#{Time.now.to_i}@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current,
      first_name: "Flow",
      last_name: "Test",
      onboarding_completed: false,
      plan_id: nil
    )
    
    sign_in user
    
    # Visit onboarding
    get users_onboarding_path
    assert_response :success
    
    # Go to plan selection
    get plan_selection_users_onboarding_path
    assert_response :success
    assert_select "h1", text: "Choose Your Plan"
    assert_select "input[type=radio][name='plan_id']", minimum: 1
  end

  test "selecting individual plan completes onboarding" do
    # Create user and sign in
    user = User.create!(
      email: "individual_test#{Time.now.to_i}@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current,
      first_name: "Individual",
      last_name: "Test",
      onboarding_completed: false,
      plan_id: nil
    )
    
    sign_in user
    
    # Get available individual plan
    individual_plan = Plan.find_by(plan_segment: "individual", active: true)
    
    # Select plan
    post update_plan_users_onboarding_path, params: {
      plan_id: individual_plan.id
    }
    
    # Should redirect to dashboard
    assert_redirected_to user_dashboard_path
    
    # User should be updated
    user.reload
    assert_equal individual_plan.id, user.plan_id
    assert user.onboarding_completed
    assert_equal "completed", user.onboarding_step
  end

  test "selecting team plan requires team name" do
    # Create user and sign in
    user = User.create!(
      email: "team_test#{Time.now.to_i}@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current,
      first_name: "Team",
      last_name: "Test",
      onboarding_completed: false,
      plan_id: nil
    )
    
    sign_in user
    
    # Get available team plan
    team_plan = Plan.find_by(plan_segment: "team", active: true)
    
    # Try to select team plan without team name
    post update_plan_users_onboarding_path, params: {
      plan_id: team_plan.id
    }
    
    # Should redirect back with error
    assert_redirected_to plan_selection_users_onboarding_path
    assert_equal "Team name is required for team plans", flash[:alert]
    
    # Select team plan with team name
    post update_plan_users_onboarding_path, params: {
      plan_id: team_plan.id,
      team_name: "Test Team"
    }
    
    # Should redirect to team dashboard
    user.reload
    assert user.owns_team?
    assert_not_nil user.team
    assert_equal "Test Team", user.team.name
    assert_redirected_to team_root_path(team_slug: user.team.slug)
  end

  test "user with existing plan bypasses onboarding" do
    # Create user with a plan
    plan = Plan.find_by(plan_segment: "individual", active: true)
    user = User.create!(
      email: "existing_test#{Time.now.to_i}@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current,
      first_name: "Existing",
      last_name: "User",
      onboarding_completed: true,
      plan_id: plan.id
    )
    
    sign_in user
    
    # Should go directly to dashboard
    get root_path
    assert_redirected_to user_dashboard_path
    
    # Trying to access onboarding should redirect to dashboard
    get users_onboarding_path
    assert_redirected_to user_dashboard_path
  end
end