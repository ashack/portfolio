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
    get users_profile_path(@direct_user.id)
    assert_response :success
    assert_match "Profile", response.body
  end

  test "should get edit" do
    get edit_users_profile_path(@direct_user.id)
    assert_response :success
    assert_match "Edit Profile", response.body
  end

  test "should update profile with valid params" do
    patch users_profile_path(@direct_user.id), params: {
      user: {
        first_name: "Updated",
        last_name: "Name",
        bio: "Updated bio",
        phone_number: "+9876543210",
        timezone: "Eastern Time (US & Canada)",
        locale: "es",
        profile_visibility: "team_only",
        linkedin_url: "https://linkedin.com/in/test",
        twitter_url: "https://twitter.com/test",
        github_url: "https://github.com/test",
        website_url: "https://example.com"
      }
    }

    # Debug validation errors if update fails
    unless response.redirect?
      puts "Response status: #{response.status}"
      puts "User errors: #{assigns(:user)&.errors&.full_messages}" if assigns(:user)
      puts "Response body snippet: #{response.body[0..500]}" if response.body
    end

    assert_redirected_to users_profile_path(@direct_user.id)
    assert_equal "Profile updated successfully.", flash[:notice]

    @direct_user.reload
    assert_equal "Updated", @direct_user.first_name
    assert_equal "Name", @direct_user.last_name
    assert_equal "Updated bio", @direct_user.bio
    assert_equal "+9876543210", @direct_user.phone_number
    assert_equal "Eastern Time (US & Canada)", @direct_user.timezone
    assert_equal "es", @direct_user.locale
    assert @direct_user.profile_visibility_team_only?
    assert_equal "https://linkedin.com/in/test", @direct_user.linkedin_url
  end

  test "should not update profile with invalid params" do
    patch users_profile_path(@direct_user.id), params: {
      user: {
        first_name: "A" * 51, # Too long
        bio: "B" * 501, # Too long
        linkedin_url: "not-a-url"
      }
    }

    assert_response :unprocessable_entity
    assert_match "error", response.body
  end

  test "should update notification preferences" do
    patch users_profile_path(@direct_user.id), params: {
      user: {
        first_name: @direct_user.first_name,
        notification_preferences: {
          email_marketing: "1",
          email_security: "1",
          frequency: "daily"
        }
      }
    }

    assert_redirected_to users_profile_path(@direct_user.id)

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

    patch users_profile_path(@direct_user.id), params: {
      user: {
        first_name: "Complete",
        last_name: "Profile",
        bio: "Complete bio"
      }
    }

    assert_redirected_to users_profile_path(@direct_user.id)

    @direct_user.reload
    assert @direct_user.profile_completion_percentage > 0
  end

  test "should show warning when trying to change email" do
    patch users_profile_path(@direct_user.id), params: {
      user: {
        first_name: @direct_user.first_name,
        email: "newemail@example.com"
      }
    }

    assert_redirected_to users_profile_path(@direct_user.id)
    assert_equal "Email changes must be requested through the email change request system for security reasons.", flash[:alert]

    # Email should not change
    @direct_user.reload
    assert_equal "direct@example.com", @direct_user.email
  end

  test "email change protection removes email from params" do
    original_email = @direct_user.email

    patch users_profile_path(@direct_user.id), params: {
      user: {
        first_name: "Updated",
        email: "hacker@example.com",
        unconfirmed_email: "hacker@example.com"
      }
    }

    assert_redirected_to users_profile_path(@direct_user.id)
    assert_equal "Profile updated successfully.", flash[:notice]
    assert_equal "Email changes must be requested through the email change request system for security reasons.", flash[:alert]

    @direct_user.reload
    assert_equal original_email, @direct_user.email
    assert_equal "Updated", @direct_user.first_name
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

    get users_profile_path(@direct_user.id)
    assert_response :success
    assert_match "75%", response.body
    assert_match /Profile Completeness/, response.body
  end

  test "should display avatar if attached" do
    @direct_user.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    get users_profile_path(@direct_user.id)
    assert_response :success
    assert_match "rounded-full", response.body
  end

  test "should display social links when present" do
    @direct_user.update(
      linkedin_url: "https://linkedin.com/in/test",
      twitter_url: "https://twitter.com/test"
    )

    get users_profile_path(@direct_user.id)
    assert_response :success
    assert_match "https://linkedin.com/in/test", response.body
    assert_match "https://twitter.com/test", response.body
  end
end
