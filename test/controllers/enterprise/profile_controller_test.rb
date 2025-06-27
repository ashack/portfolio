require "test_helper"

class Enterprise::ProfileControllerTest < ActionDispatch::IntegrationTest
  def setup
    @enterprise_group = enterprise_groups(:techcorp)
    @enterprise_user = sign_in_with(
      email: "user@techcorp.com",
      first_name: "Enterprise",
      last_name: "User",
      user_type: "enterprise",
      enterprise_group: @enterprise_group,
      enterprise_group_role: "member"
    )
  end

  test "should get show" do
    get enterprise_profile_path(@enterprise_group.slug)
    assert_response :success
    assert_select "h1", "Profile"
  end

  test "should get edit" do
    get edit_enterprise_profile_path(@enterprise_group.slug)
    assert_response :success
    assert_select "h1", "Edit Profile"
  end

  test "should update profile with valid params" do
    patch enterprise_profile_path(@enterprise_group.slug), params: {
      user: {
        first_name: "Updated",
        last_name: "EnterpriseUser",
        bio: "Enterprise user bio",
        phone_number: "+1234567890",
        timezone: "Asia/Tokyo",
        locale: "en",
        profile_visibility: "private_profile"
      }
    }
    
    assert_redirected_to enterprise_profile_path(@enterprise_group.slug)
    assert_equal "Profile updated successfully.", flash[:notice]
    
    @enterprise_user.reload
    assert_equal "Updated", @enterprise_user.first_name
    assert_equal "EnterpriseUser", @enterprise_user.last_name
    assert_equal "Enterprise user bio", @enterprise_user.bio
    assert_equal "Asia/Tokyo", @enterprise_user.timezone
  end

  test "should update social links" do
    patch enterprise_profile_path(@enterprise_group.slug), params: {
      user: {
        first_name: @enterprise_user.first_name,
        linkedin_url: "https://linkedin.com/in/enterprise",
        github_url: "https://github.com/enterprise"
      }
    }
    
    assert_redirected_to enterprise_profile_path(@enterprise_group.slug)
    
    @enterprise_user.reload
    assert_equal "https://linkedin.com/in/enterprise", @enterprise_user.linkedin_url
    assert_equal "https://github.com/enterprise", @enterprise_user.github_url
  end

  test "should update notification preferences" do
    patch enterprise_profile_path(@enterprise_group.slug), params: {
      user: {
        first_name: @enterprise_user.first_name,
        notification_preferences: {
          email_updates: "1",
          email_security: "1",
          frequency: "weekly"
        }
      }
    }
    
    assert_redirected_to enterprise_profile_path(@enterprise_group.slug)
    
    @enterprise_user.reload
    assert_equal "1", @enterprise_user.notification_preferences["email_updates"]
    assert_equal "1", @enterprise_user.notification_preferences["email_security"]
    assert_equal "weekly", @enterprise_user.notification_preferences["frequency"]
  end

  test "should redirect non-enterprise users" do
    direct_user = sign_in_with(email: "direct@example.com", user_type: "direct")
    
    get enterprise_profile_path(@enterprise_group.slug)
    assert_redirected_to root_path
    assert_equal "Access denied.", flash[:alert]
  end

  test "enterprise admin should see billing notifications option" do
    enterprise_admin = sign_in_with(
      email: "admin@techcorp.com",
      user_type: "enterprise",
      enterprise_group: @enterprise_group,
      enterprise_group_role: "admin"
    )
    
    get edit_enterprise_profile_path(@enterprise_group.slug)
    assert_response :success
    assert_match /Billing Notifications/, response.body
  end

  test "should show purple theme elements" do
    get enterprise_profile_path(@enterprise_group.slug)
    assert_response :success
    assert_select "a[class*='bg-purple-600']"
  end

  test "should display enterprise organization info" do
    get enterprise_profile_path(@enterprise_group.slug)
    assert_response :success
    assert_match @enterprise_group.name, response.body
    assert_select "span[class*='bg-purple-100']"
  end

  test "should calculate profile completion after update" do
    @enterprise_user.update_columns(
      profile_completion_percentage: 0,
      bio: nil,
      timezone: "UTC"
    )
    
    patch enterprise_profile_path(@enterprise_group.slug), params: {
      user: {
        bio: "Complete bio",
        timezone: "America/New_York"
      }
    }
    
    assert_redirected_to enterprise_profile_path(@enterprise_group.slug)
    
    @enterprise_user.reload
    assert @enterprise_user.profile_completion_percentage > 0
  end

  test "should validate URL formats" do
    patch enterprise_profile_path(@enterprise_group.slug), params: {
      user: {
        linkedin_url: "not-a-url",
        website_url: "also-not-a-url"
      }
    }
    
    assert_response :unprocessable_entity
    assert_select "h3", "Please fix the following errors:"
  end

  test "should not allow email changes through profile update" do
    original_email = @enterprise_user.email
    
    patch enterprise_profile_path(@enterprise_group.slug), params: {
      user: {
        first_name: "Updated",
        email: "newemail@example.com"
      }
    }
    
    assert_redirected_to enterprise_profile_path(@enterprise_group.slug)
    assert_equal "Profile updated successfully.", flash[:notice]
    assert_equal "Email changes must be requested through the email change request system for security reasons.", flash[:alert]
    
    @enterprise_user.reload
    assert_equal original_email, @enterprise_user.email
    assert_equal "Updated", @enterprise_user.first_name
  end

  test "email change protection removes sensitive fields from params" do
    original_email = @enterprise_user.email
    
    patch enterprise_profile_path(@enterprise_group.slug), params: {
      user: {
        bio: "Updated enterprise bio",
        email: "attacker@example.com",
        unconfirmed_email: "attacker@example.com"
      }
    }
    
    assert_redirected_to enterprise_profile_path(@enterprise_group.slug)
    
    @enterprise_user.reload
    assert_equal original_email, @enterprise_user.email
    assert_nil @enterprise_user.unconfirmed_email
    assert_equal "Updated enterprise bio", @enterprise_user.bio
  end
  
  test "should show email field as read-only in edit form" do
    get edit_enterprise_profile_path(@enterprise_group.slug)
    assert_response :success
    
    # Check that email field is read-only
    assert_select "input[type='email'][readonly]"
    assert_select "a", text: "Request Change"
  end
end