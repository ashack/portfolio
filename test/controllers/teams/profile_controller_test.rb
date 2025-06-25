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
    assert_select "h1", "Profile"
  end

  test "should get edit" do
    get edit_teams_profile_path(team_slug: @team.slug, id: @team_member)
    assert_response :success
    assert_select "h1", "Edit Profile"
  end

  test "should update profile with valid params" do
    patch teams_profile_path(team_slug: @team.slug, id: @team_member), params: {
      user: {
        first_name: "Updated",
        last_name: "TeamMember",
        bio: "Team member bio",
        phone_number: "+1234567890",
        timezone: "Europe/London",
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
    assert_equal "Europe/London", @team_member.timezone
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
    other_member = sign_in_with(
      email: "other@acmecorp.com",
      user_type: "invited",
      team: @team,
      team_role: "member"
    )
    
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
    assert_match /Billing Notifications/, response.body
  end

  test "regular member should not see billing notifications option" do
    get edit_teams_profile_path(team_slug: @team.slug, id: @team_member)
    assert_response :success
    assert_no_match /Billing Notifications/, response.body
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
end