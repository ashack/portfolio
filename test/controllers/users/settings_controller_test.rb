require "test_helper"

class Users::SettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = sign_in_with(
      email: "john.doe@example.com",
      user_type: "direct",
      first_name: "John",
      last_name: "Doe"
    )
  end

  test "should get show" do
    get users_settings_url
    assert_response :success
    assert_select "h1", "Account Settings"
    
    # Verify email field is read-only
    assert_select "input[type='email'][readonly]"
    assert_select "a", text: "Request Change"
  end

  test "should update user settings" do
    patch users_settings_url, params: {
      user: {
        first_name: "Jane",
        last_name: "Smith"
      }
    }
    
    assert_redirected_to users_settings_url
    assert_equal "Settings updated successfully.", flash[:notice]
    
    @user.reload
    assert_equal "Jane", @user.first_name
    assert_equal "Smith", @user.last_name
  end

  test "should not update email even if included in params" do
    original_email = @user.email
    
    patch users_settings_url, params: {
      user: {
        first_name: "Jane",
        email: "new.email@example.com"
      }
    }
    
    assert_redirected_to users_settings_url
    assert_equal "Settings updated successfully.", flash[:notice]
    assert_equal "Email changes must be requested through the email change request system for security reasons.", flash[:alert]
    
    @user.reload
    assert_equal original_email, @user.email
    assert_equal "Jane", @user.first_name
  end

  test "should handle validation errors" do
    patch users_settings_url, params: {
      user: {
        first_name: "Jane123", # Invalid name with numbers
        last_name: "Smith"
      }
    }
    
    assert_response :unprocessable_entity
    assert_select "h3", "Please fix the following errors:"
  end

  test "requires authentication" do
    sign_out
    
    get users_settings_url
    assert_redirected_to new_user_session_path
    
    patch users_settings_url, params: { user: { first_name: "Test" } }
    assert_redirected_to new_user_session_path
  end

  test "email change protection logs security warning" do
    # Capture logs during the request
    Rails.logger.expects(:warn).with(includes("[SECURITY] Email change attempt"))
    
    patch users_settings_url, params: {
      user: {
        email: "hacker@example.com",
        first_name: "Test"
      }
    }
    
    @user.reload
    assert_not_equal "hacker@example.com", @user.email
  end
end