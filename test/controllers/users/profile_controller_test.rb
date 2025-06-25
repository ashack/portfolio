require "test_helper"

class Users::ProfileControllerTest < ActionDispatch::IntegrationTest
  def setup
    @direct_user = sign_in_with(
      email: "direct@example.com",
      first_name: "Direct",
      last_name: "User",
      user_type: "direct",
      bio: "Test bio",
      phone_number: "+1234567890"
    )
  end

  test "should get show" do
    get users_profile_path(@direct_user)
    assert_response :success
    assert_select "h1", "Profile"
  end

  test "should get edit" do
    get edit_users_profile_path(@direct_user)
    assert_response :success
    assert_select "h1", "Edit Profile"
  end

  test "should update profile with valid params" do
    patch users_profile_path(@direct_user), params: {
      user: {
        first_name: "Updated",
        last_name: "Name",
        bio: "Updated bio",
        phone_number: "+9876543210",
        timezone: "America/New_York",
        locale: "es",
        profile_visibility: "team_only",
        linkedin_url: "https://linkedin.com/in/test",
        twitter_url: "https://twitter.com/test",
        github_url: "https://github.com/test",
        website_url: "https://example.com"
      }
    }
    
    assert_redirected_to users_profile_path(@direct_user)
    assert_equal "Profile updated successfully.", flash[:notice]
    
    @direct_user.reload
    assert_equal "Updated", @direct_user.first_name
    assert_equal "Name", @direct_user.last_name
    assert_equal "Updated bio", @direct_user.bio
    assert_equal "+9876543210", @direct_user.phone_number
    assert_equal "America/New_York", @direct_user.timezone
    assert_equal "es", @direct_user.locale
    assert_equal "team_only", @direct_user.profile_visibility
    assert_equal "https://linkedin.com/in/test", @direct_user.linkedin_url
  end

  test "should not update profile with invalid params" do
    patch users_profile_path(@direct_user), params: {
      user: {
        first_name: "A" * 51, # Too long
        bio: "B" * 501, # Too long
        linkedin_url: "not-a-url"
      }
    }
    
    assert_response :unprocessable_entity
    assert_select "h3", "Please fix the following errors:"
  end

  test "should update notification preferences" do
    patch users_profile_path(@direct_user), params: {
      user: {
        first_name: @direct_user.first_name,
        notification_preferences: {
          email_marketing: "1",
          email_security: "1",
          frequency: "daily"
        }
      }
    }
    
    assert_redirected_to users_profile_path(@direct_user)
    
    @direct_user.reload
    assert_equal "1", @direct_user.notification_preferences["email_marketing"]
    assert_equal "1", @direct_user.notification_preferences["email_security"]
    assert_equal "daily", @direct_user.notification_preferences["frequency"]
  end

  test "should calculate profile completion after update" do
    # Start with incomplete profile
    @direct_user.update_columns(
      first_name: nil,
      last_name: nil,
      bio: nil,
      profile_completion_percentage: 0
    )
    
    patch users_profile_path(@direct_user), params: {
      user: {
        first_name: "Complete",
        last_name: "Profile",
        bio: "Complete bio"
      }
    }
    
    assert_redirected_to users_profile_path(@direct_user)
    
    @direct_user.reload
    assert @direct_user.profile_completion_percentage > 0
  end

  test "should show warning when trying to change email" do
    patch users_profile_path(@direct_user), params: {
      user: {
        first_name: @direct_user.first_name,
        email: "newemail@example.com"
      }
    }
    
    assert_redirected_to users_profile_path(@direct_user)
    
    # Email should not change
    @direct_user.reload
    assert_equal "direct@example.com", @direct_user.email
  end

  test "should redirect if accessing another user's profile" do
    other_user = User.create!(
      email: "other@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current,
      timezone: "UTC",
      locale: "en",
      profile_visibility: 0
    )
    
    get users_profile_path(other_user, id: other_user.id)
    assert_redirected_to root_path
    assert_equal "Access denied.", flash[:alert]
  end

  test "should display profile completion information" do
    @direct_user.update(profile_completion_percentage: 75)
    
    get users_profile_path(@direct_user)
    assert_response :success
    assert_select "span", "75%"
    assert_match /Profile Completeness/, response.body
  end

  test "should display avatar if attached" do
    @direct_user.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )
    
    get users_profile_path(@direct_user)
    assert_response :success
    assert_select "img[class*='rounded-full']"
  end

  test "should display social links when present" do
    @direct_user.update(
      linkedin_url: "https://linkedin.com/in/test",
      twitter_url: "https://twitter.com/test"
    )
    
    get users_profile_path(@direct_user)
    assert_response :success
    assert_select "a[href='https://linkedin.com/in/test']"
    assert_select "a[href='https://twitter.com/test']"
  end
end