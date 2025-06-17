require "application_system_test_case"

class UserRegistrationTest < ApplicationSystemTestCase
  test "visiting the registration page" do
    visit new_user_registration_path

    assert_selector "h1", text: "Sign Up"
    assert_field "Email"
    assert_field "Password"
    assert_field "Password confirmation"
    assert_button "Sign up"
  end

  test "registering a new direct user" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    fill_in "First name", with: "New"
    fill_in "Last name", with: "User"

    click_button "Sign up"

    assert_text "Welcome! You have signed up successfully"
    assert_current_path dashboard_root_path
  end

  test "registration with invalid data shows errors" do
    visit new_user_registration_path

    # Submit empty form
    click_button "Sign up"

    assert_text "Email can't be blank"
    assert_text "Password can't be blank"
  end

  test "registration with mismatched passwords shows error" do
    visit new_user_registration_path

    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "differentpassword"

    click_button "Sign up"

    assert_text "Password confirmation doesn't match Password"
  end

  test "registration with existing email shows error" do
    # Create existing user
    User.create!(
      email: "existing@example.com",
      password: "password123",
      confirmed_at: Time.current
    )

    visit new_user_registration_path

    fill_in "Email", with: "existing@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

    click_button "Sign up"

    assert_text "Email has already been taken"
  end
end
