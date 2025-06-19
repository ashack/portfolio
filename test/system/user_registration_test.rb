require "application_system_test_case"

class UserRegistrationTest < ApplicationSystemTestCase
  def setup
    # Create test plans
    @free_plan = Plan.create!(
      name: "Individual Free",
      plan_type: "individual",
      amount_cents: 0,
      features: [ "basic_dashboard", "email_support" ],
      active: true
    )

    @pro_plan = Plan.create!(
      name: "Individual Pro",
      plan_type: "individual",
      stripe_price_id: "price_individual_pro",
      amount_cents: 1900,
      interval: "month",
      features: [ "basic_dashboard", "advanced_features", "priority_support" ],
      active: true
    )
  end
  test "visiting the registration page" do
    visit new_user_registration_path

    assert_selector "h2", text: "Create your account"
    assert_field "Email"
    assert_field "Password"
    assert_field "Password confirmation"
    assert_button "Create Account"

    # Check plan selection is shown
    assert_text "Choose Your Plan"
    assert_text @free_plan.name
    assert_text @pro_plan.name
  end

  test "registering a new direct user with plan" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "Password123!"
    fill_in "Password confirmation", with: "Password123!"
    fill_in "First name", with: "New"
    fill_in "Last name", with: "User"

    # Select pro plan
    choose "plan_#{@pro_plan.id}"

    click_button "Create Account"

    # Check user was created with correct attributes
    user = User.find_by(email: "newuser@example.com")
    assert user.present?
    assert_equal "direct", user.user_type
    assert_equal @pro_plan, user.plan

    assert_current_path user_dashboard_path
  end

  test "registration with invalid data shows errors" do
    visit new_user_registration_path

    # Submit empty form
    click_button "Create Account"

    assert_text "can't be blank"
  end

  test "registration with mismatched passwords shows error" do
    visit new_user_registration_path

    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "Password123!"
    fill_in "Password confirmation", with: "differentpassword"

    click_button "Create Account"

    assert_text "doesn't match"
  end

  test "registration with existing email shows error" do
    # Create existing user
    User.create!(
      email: "existing@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current
    )

    visit new_user_registration_path

    fill_in "Email", with: "existing@example.com"
    fill_in "Password", with: "Password123!"
    fill_in "Password confirmation", with: "Password123!"

    click_button "Create Account"

    assert_text "already taken"
  end

  test "user can register with free plan by default" do
    visit new_user_registration_path

    fill_in "Email", with: "freeuser@example.com"
    fill_in "Password", with: "Password123!"
    fill_in "Password confirmation", with: "Password123!"
    fill_in "First name", with: "Free"
    fill_in "Last name", with: "User"

    # Select free plan (should be selected by default)
    choose "plan_#{@free_plan.id}"

    click_button "Create Account"

    # Check user was created with free plan
    user = User.find_by(email: "freeuser@example.com")
    assert user.present?
    assert_equal @free_plan, user.plan
  end
end
