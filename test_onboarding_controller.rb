# Test onboarding controller directly
require 'rails/test_help'

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.find_by(email: "onboarding@example.com")
    @individual_plan = Plan.find_by(plan_segment: "individual", active: true)
  end
  
  def test_onboarding_redirect
    # Sign in the user
    post user_session_path, params: {
      user: { email: @user.email, password: "Password123\!" }
    }
    
    # Check if we're redirected to onboarding
    get root_path
    assert_redirected_to users_onboarding_path
    puts "✓ User is redirected to onboarding"
    
    # Visit onboarding welcome page
    get users_onboarding_path
    assert_response :success
    puts "✓ Onboarding welcome page loads successfully"
    
    # Go to plan selection
    get plan_selection_users_onboarding_path
    assert_response :success
    puts "✓ Plan selection page loads successfully"
    
    # Select a plan
    post update_plan_users_onboarding_path, params: {
      plan_id: @individual_plan.id
    }
    
    @user.reload
    assert @user.onboarding_completed?
    assert_equal @individual_plan.id, @user.plan_id
    puts "✓ Plan selected and onboarding completed"
    puts "✓ User now has plan: #{@user.plan.name}"
  end
end

test = OnboardingControllerTest.new("test_onboarding_redirect")
test.setup
test.test_onboarding_redirect
