require "test_helper"

class EmailChangeProtectionTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User",
      user_type: "direct",
      confirmed_at: Time.current
    )
    sign_in @user
  end

  test "concern detects email change attempt in user profile update" do
    patch users_profile_path(@user), params: {
      user: {
        first_name: "Updated",
        email: "new@example.com"
      }
    }

    assert_redirected_to users_profile_path
    assert_equal "Email changes must be requested through the email change request system for security reasons.", flash[:alert]

    @user.reload
    assert_equal "test@example.com", @user.email
    assert_equal "Updated", @user.first_name
  end

  test "concern removes email and unconfirmed_email from params" do
    patch users_profile_path(@user), params: {
      user: {
        first_name: "Updated",
        email: "attacker@example.com",
        unconfirmed_email: "attacker@example.com"
      }
    }

    assert_redirected_to users_profile_path

    @user.reload
    assert_equal "test@example.com", @user.email
    assert_nil @user.unconfirmed_email
  end

  test "concern only triggers when email is different" do
    patch users_profile_path(@user), params: {
      user: {
        first_name: "Updated",
        email: @user.email # Same email
      }
    }

    assert_redirected_to users_profile_path
    assert_nil flash[:alert] # No warning since email didn't change
  end

  test "concern handles various param structures" do
    # Test with user params
    patch users_profile_path(@user), params: {
      user: {
        email: "new@example.com"
      }
    }

    @user.reload
    assert_equal "test@example.com", @user.email
  end

  test "concern logs security warning" do
    logs = []
    Rails.logger.stub :warn, ->(msg) { logs << msg } do
      patch users_profile_path(@user), params: {
        user: {
          email: "attacker@example.com"
        }
      }
    end

    assert logs.any? { |log| log.include?("[SECURITY] Email change attempt blocked") }
    assert logs.any? { |log| log.include?("Attempted email: attacker@example.com") }
  end
end
