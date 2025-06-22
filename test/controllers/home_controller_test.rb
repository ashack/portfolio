require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  # ========== CRITICAL TESTS (Weight 7-8) ==========

  # Weight: 8 - Critical routing matrix for all user types
  test "routes users to correct dashboards based on user type and role" do
    routing_matrix = [
      # [email, user_type, system_role, team, expected_path]
      [ "superadmin@example.com", "direct", "super_admin", nil, :admin_super_root_path ],
      [ "siteadmin@example.com", "direct", "site_admin", nil, :admin_site_root_path ],
      [ "directuser@example.com", "direct", "user", nil, :user_dashboard_path ]
    ]

    routing_matrix.each do |email, user_type, system_role, team, expected_path|
      sign_out :user if defined?(current_user)

      user = sign_in_with(
        email: email,
        user_type: user_type,
        system_role: system_role
      )

      get root_path
      assert_redirected_to send(expected_path),
        "Expected #{system_role} #{user_type} user to be redirected to #{expected_path}"
    end
  end

  # Weight: 7 - Team member routing
  test "routes invited team members to their team dashboard" do
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

  # ========== MEDIUM PRIORITY TESTS (Weight 5-6) ==========

  # Weight: 5 - Public access control
  test "allows unauthenticated access to homepage" do
    sign_out :user if defined?(current_user)

    get root_path
    assert_response :success
    assert_match /Welcome/i, response.body
  end
end
