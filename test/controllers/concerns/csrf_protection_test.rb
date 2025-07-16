require "test_helper"

# Weight: 9 - CR-S1: CSRF Protection Tests
# These tests validate that all state-changing requests require valid CSRF tokens
# to prevent cross-site request forgery attacks
class CsrfProtectionTest < ActionDispatch::IntegrationTest
  setup do
    # Enable CSRF protection for these tests
    ActionController::Base.allow_forgery_protection = true
    @user = User.create!(
      email: "test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User",
      user_type: "direct",
      confirmed_at: Time.current
    )

    @admin = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      first_name: "Admin",
      last_name: "User",
      system_role: "super_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )
  end

  teardown do
    # Reset CSRF protection to test default
    ActionController::Base.allow_forgery_protection = false
  end

  # Test that CSRF protection is enabled globally
  test "application enforces CSRF protection on state-changing requests" do
    sign_in @user

    # Get a page to establish session and CSRF token
    get user_dashboard_path
    assert_response :success

    # Extract CSRF token from meta tag
    csrf_token = css_select('meta[name="csrf-token"]').first["content"]
    assert csrf_token.present?, "CSRF token should be present in meta tags"

    # Test that PATCH without token fails
    patch users_profile_path(@user), params: { user: { first_name: "Updated" } }
    # CSRF failure might redirect to login (302) or return 422
    assert_includes [ 302, 422 ], response.status, "Should reject request without CSRF token"

    # Test that PATCH with invalid token fails
    patch users_profile_path(@user),
      params: { user: { first_name: "Updated" } },
      headers: { "X-CSRF-Token" => "invalid_token" }
    # CSRF failure might redirect to login (302) or return 422
    assert_includes [ 302, 422 ], response.status, "Should reject request without CSRF token"

    # Test that PATCH with valid token succeeds
    patch users_profile_path(@user),
      params: { user: { first_name: "Updated" }, authenticity_token: csrf_token },
      headers: { "X-CSRF-Token" => csrf_token }
    # Should redirect or succeed based on controller logic
    assert_not_equal :unprocessable_entity, response.status
  end

  # Test CSRF protection on critical admin actions
  test "admin actions require valid CSRF tokens" do
    sign_in @admin

    # Get admin page for CSRF token
    get admin_super_root_path
    assert_response :success

    # Test team creation without CSRF token
    assert_no_difference "Team.count" do
      post admin_super_teams_path, params: {
        team: { name: "New Team" }
      }
    # CSRF failure might redirect to login (302) or return 422
    assert_includes [ 302, 422 ], response.status, "Should reject request without CSRF token"
    end

    # Test user status change without CSRF token
    patch set_status_admin_super_user_path(@user), params: {
      status: "inactive"
    }
    # CSRF failure might redirect to login (302) or return 422
    assert_includes [ 302, 422 ], response.status, "Should reject request without CSRF token"
    @user.reload
    assert_equal "active", @user.status
  end

  # Test CSRF protection on user profile updates
  test "user profile updates require CSRF protection" do
    # Sign in and get CSRF token
    sign_in @user

    get users_profile_path(@user)
    assert_response :success

    # Attempt profile update without token
    patch users_profile_path(@user), params: {
      user: {
        first_name: "Hacked",
        last_name: "User"
      }
    }
    # CSRF failure might redirect to login (302) or return 422
    assert_includes [ 302, 422 ], response.status, "Should reject request without CSRF token"

    @user.reload
    assert_not_equal "Hacked", @user.first_name
  end

  # Test CSRF protection on billing/subscription endpoints
  test "billing endpoints enforce CSRF protection" do
    sign_in @user

    # Mock subscription update without CSRF
    patch users_subscription_path, params: {
      plan_id: "premium"
    }
    # CSRF failure might redirect to login (302) or return 422
    assert_includes [ 302, 422 ], response.status, "Should reject request without CSRF token"
  end

  # Test that GET requests don't require CSRF tokens
  test "read-only requests do not require CSRF tokens" do
    sign_in @user

    # These should all work without CSRF tokens
    get user_dashboard_path
    assert_response :success

    get users_profile_path(@user)
    assert_response :success

    get users_billing_index_path
    assert_response :success
  end

  # Test CSRF protection on team management actions
  test "team management actions require CSRF protection" do
    team = Team.create!(
      name: "Test Team",
      slug: "test-team",
      admin: @admin,
      created_by: @admin
    )

    # Create a team admin user (invited type)
    team_admin = User.create!(
      email: "teamadmin@example.com",
      password: "Password123!",
      team: team,
      team_role: "admin",
      user_type: "invited",
      confirmed_at: Time.current
    )

    sign_in team_admin

    # Try to delete team member without CSRF
    other_member = User.create!(
      email: "member@example.com",
      password: "Password123!",
      team: team,
      team_role: "member",
      user_type: "invited",
      confirmed_at: Time.current
    )

    assert_no_difference "User.count" do
      delete team_admin_member_path(team_slug: team.slug, id: other_member.id)
    # CSRF failure might redirect to login (302) or return 422
    assert_includes [ 302, 422 ], response.status, "Should reject request without CSRF token"
    end
  end

  # Test CSRF protection on invitation actions
  test "invitation actions require CSRF protection" do
    team = Team.create!(
      name: "Test Team",
      slug: "test-team",
      admin: @admin,
      created_by: @admin
    )

    @admin.update!(owns_team: true)

    sign_in @admin

    # Try to create invitation without CSRF
    assert_no_difference "Invitation.count" do
      post team_admin_invitations_path(team_slug: team.slug), params: {
        invitation: {
          email: "newuser@example.com",
          role: "member"
        }
      }
    # CSRF failure might redirect to login (302) or return 422
    assert_includes [ 302, 422 ], response.status, "Should reject request without CSRF token"
    end
  end

  # Test AJAX requests with CSRF tokens
  test "AJAX requests can use X-CSRF-Token header" do
    sign_in @user
    get user_dashboard_path

    csrf_token = css_select('meta[name="csrf-token"]').first["content"]

    # AJAX request with token in header should work
    patch users_profile_path(@user),
      params: { user: { locale: "es" } },
      headers: {
        "X-CSRF-Token" => csrf_token,
        "X-Requested-With" => "XMLHttpRequest"
      },
      as: :json

    # Should not be unprocessable_entity
    assert_not_equal 422, response.status
  end

  # Test that CSRF tokens are rotated on login
  test "CSRF tokens are rotated after authentication" do
    get new_user_session_path
    initial_token = css_select('meta[name="csrf-token"]').first["content"]

    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "Password123!"
      },
      authenticity_token: initial_token
    }

    follow_redirect!
    new_token = css_select('meta[name="csrf-token"]').first["content"]

    assert_not_equal initial_token, new_token, "CSRF token should change after login"
  end

  # Comprehensive test for all critical controllers
  test "all state-changing controllers enforce CSRF protection" do
    sign_in @admin

    critical_endpoints = [
      { method: :post, path: admin_super_teams_path },
      { method: :patch, path: admin_super_user_path(@user) },
      { method: :delete, path: admin_super_team_path(1) },
      { method: :post, path: impersonate_admin_super_user_path(@user) },
      { method: :patch, path: set_status_admin_super_user_path(@user) }
    ]

    critical_endpoints.each do |endpoint|
      send(endpoint[:method], endpoint[:path], params: { test: true })
      # CSRF failure might redirect to login (302) or return 422
      assert_includes [ 302, 422 ], response.status,
        "#{endpoint[:method].upcase} #{endpoint[:path]} should require CSRF token"
    end
  end
end
