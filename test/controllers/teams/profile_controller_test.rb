require "test_helper"

class Teams::ProfileControllerTest < ActionDispatch::IntegrationTest
  def setup
    @team = teams(:acme_corp)
    @team_member = sign_in_with(
      email: "member@acmecorp.com",
      first_name: "Team",
      last_name: "Member",
      user_type: "invited",
      team: @team,
      team_role: "member"
    )
  end

  test "should get show" do
    get teams_profile_path(team_slug: @team.slug, id: @team_member)
    assert_response :success
    assert_match "Profile", response.body
  end

  test "should get edit" do
    get edit_teams_profile_path(team_slug: @team.slug, id: @team_member)
    assert_response :success
    assert_match "Edit Team Profile", response.body
  end

  test "should update profile with valid params" do
    patch teams_profile_path(team_slug: @team.slug, id: @team_member), params: {
      user: {
        first_name: "Updated",
        last_name: "TeamMember",
        bio: "Team member bio",
        phone_number: "+1234567890",
        timezone: "London",
        locale: "en",
        profile_visibility: "team_only"
      }
    }

    assert_redirected_to teams_profile_path(team_slug: @team.slug, id: @team_member)
    assert_equal "Profile updated successfully.", flash[:notice]

    @team_member.reload
    assert_equal "Updated", @team_member.first_name
    assert_equal "TeamMember", @team_member.last_name
    assert_equal "Team member bio", @team_member.bio
    assert_equal "London", @team_member.timezone
  end

  test "should update avatar" do
    patch teams_profile_path(team_slug: @team.slug, id: @team_member), params: {
      user: {
        first_name: @team_member.first_name,
        avatar_url: "https://example.com/avatar.jpg"
      }
    }

    assert_redirected_to teams_profile_path(team_slug: @team.slug, id: @team_member)

    @team_member.reload
    assert_equal "https://example.com/avatar.jpg", @team_member.avatar_url
  end

  test "should update notification preferences" do
    patch teams_profile_path(team_slug: @team.slug, id: @team_member), params: {
      user: {
        first_name: @team_member.first_name,
        notification_preferences: {
          activity_team: "1",
          activity_mentions: "1",
          frequency: "realtime"
        }
      }
    }

    assert_redirected_to teams_profile_path(team_slug: @team.slug, id: @team_member)

    @team_member.reload
    assert_equal "1", @team_member.notification_preferences["activity_team"]
    assert_equal "1", @team_member.notification_preferences["activity_mentions"]
    assert_equal "realtime", @team_member.notification_preferences["frequency"]
  end

  test "should redirect if accessing another user's profile" do
    # Create another member in the team
    other_member = User.create!(
      email: "other@acmecorp.com",
      password: "Password123!",
      first_name: "Other",
      last_name: "Member",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )

    # Try to access other member's profile while signed in as @team_member
    get teams_profile_path(team_slug: @team.slug, id: other_member)
    assert_redirected_to team_root_path(team_slug: @team.slug)
    assert_equal "Access denied.", flash[:alert]
  end

  test "team admin should see billing notifications option" do
    team_admin = sign_in_with(
      email: "admin@acmecorp.com",
      user_type: "invited",
      team: @team,
      team_role: "admin"
    )

    get edit_teams_profile_path(team_slug: @team.slug, id: team_admin)
    assert_response :success
    assert_match /<h4[^>]*>Billing Notifications<\/h4>/, response.body
  end

  test "regular member should not see billing notifications option" do
    get edit_teams_profile_path(team_slug: @team.slug, id: @team_member)
    assert_response :success
    assert_no_match /<h4[^>]*>Billing Notifications<\/h4>/, response.body
  end

  test "should calculate profile completion after update" do
    @team_member.update_columns(
      profile_completion_percentage: 0,
      bio: nil,
      phone_number: nil
    )

    patch teams_profile_path(team_slug: @team.slug, id: @team_member), params: {
      user: {
        bio: "New bio",
        phone_number: "+1234567890"
      }
    }

    assert_redirected_to teams_profile_path(team_slug: @team.slug, id: @team_member)

    @team_member.reload
    assert @team_member.profile_completion_percentage > 0
  end

  test "should not allow email changes through profile update" do
    original_email = @team_member.email

    patch teams_profile_path(team_slug: @team.slug, id: @team_member), params: {
      user: {
        first_name: "Updated",
        email: "newemail@example.com"
      }
    }

    assert_redirected_to teams_profile_path(team_slug: @team.slug, id: @team_member)
    assert_equal "Profile updated successfully.", flash[:notice]
    assert_equal "Email changes must be requested through the email change request system for security reasons.", flash[:alert]

    @team_member.reload
    assert_equal original_email, @team_member.email
    assert_equal "Updated", @team_member.first_name
  end

  test "email change protection removes email and unconfirmed_email from params" do
    original_email = @team_member.email

    patch teams_profile_path(team_slug: @team.slug, id: @team_member), params: {
      user: {
        bio: "Updated bio",
        email: "attacker@example.com",
        unconfirmed_email: "attacker@example.com"
      }
    }

    assert_redirected_to teams_profile_path(team_slug: @team.slug, id: @team_member)

    @team_member.reload
    assert_equal original_email, @team_member.email
    assert_nil @team_member.unconfirmed_email
    assert_equal "Updated bio", @team_member.bio
  end
end
