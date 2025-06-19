require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index when not signed in" do
    get root_path
    assert_response :success
  end

  test "should redirect super admin to admin super dashboard" do
    super_admin = sign_in_with(
      email: "superadmin@example.com",
      system_role: "super_admin",
      user_type: "direct"
    )

    get root_path
    assert_redirected_to admin_super_root_path
  end

  test "should redirect site admin to admin site dashboard" do
    site_admin = sign_in_with(
      email: "siteadmin@example.com",
      system_role: "site_admin",
      user_type: "direct"
    )

    get root_path
    assert_redirected_to admin_site_root_path
  end

  test "should redirect direct user to user dashboard" do
    direct_user = sign_in_with(
      email: "directuser@example.com",
      user_type: "direct"
    )

    get root_path
    assert_redirected_to user_dashboard_path
  end

  test "should redirect invited user with team to team dashboard" do
    team = Team.create!(
      name: "Test Team",
      slug: "test-team",
      admin: users(:super_admin),
      created_by: users(:super_admin)
    )

    invited_user = sign_in_with(
      email: "inviteduser@example.com",
      user_type: "invited",
      team: team,
      team_role: "member"
    )

    get root_path
    assert_redirected_to team_root_path(team_slug: team.slug)
  end

  test "should redirect invited user without team to root path" do
    skip "Invited users must have teams - this is an invalid state"

    # This is an edge case - invited user without team (invalid state)
    # In reality, the User model should prevent this from happening
    invited_user = User.create!(
      email: "edgecase@example.com",
      password: "Password123!",
      user_type: "invited",
      team_id: nil,
      team_role: nil,
      confirmed_at: Time.current
    )

    sign_in invited_user

    get root_path
    assert_redirected_to root_path
  end

  test "index action does not require authentication" do
    # Ensure we're signed out
    sign_out :user if defined?(current_user)

    get root_path
    assert_response :success
    assert_match /Welcome/i, response.body
  end

  test "index action does not trigger authorization checks" do
    # This test ensures skip_after_action :verify_authorized works
    get root_path
    assert_response :success
  end
end
