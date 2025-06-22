require "test_helper"

class Admin::Super::DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @super_admin = sign_in_with(
      email: "superadmin@example.com",
      system_role: "super_admin",
      user_type: "direct"
    )
  end

  # ========== CRITICAL TESTS (Weight 8-9) ==========

  # Weight: 9 - Critical permission boundary
  test "denies access to non-super-admins" do
    # Test site admin access
    sign_out @super_admin
    site_admin = sign_in_with(
      email: "siteadmin@example.com",
      system_role: "site_admin",
      user_type: "direct"
    )

    get admin_super_root_path
    assert_redirected_to root_path
    assert_equal "You must be a super admin to access this area.", flash[:alert]

    # Test regular user access
    sign_out site_admin
    regular_user = sign_in_with(
      email: "regular@example.com",
      user_type: "direct"
    )

    get admin_super_root_path
    assert_redirected_to root_path
    assert_equal "You must be a super admin to access this area.", flash[:alert]
  end

  # Weight: 8 - Security requirement
  test "requires authentication" do
    sign_out @super_admin

    get admin_super_root_path
    assert_redirected_to new_user_session_path
  end

  # ========== MEDIUM PRIORITY TESTS (Weight 5-6) ==========

  # Weight: 6 - Data loading and statistics (consolidated)
  test "loads dashboard with comprehensive statistics and recent data" do
    # Create test data
    site_admin = User.create!(
      email: "siteadmin@example.com",
      password: "Password123!",
      system_role: "site_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )

    direct_user = User.create!(
      email: "directuser@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    inactive_user = User.create!(
      email: "inactive@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "inactive",
      confirmed_at: Time.current
    )

    team = Team.create!(
      name: "Test Team",
      admin: @super_admin,
      created_by: @super_admin
    )

    team_member = User.create!(
      email: "teammember@example.com",
      password: "Password123!",
      user_type: "invited",
      team: team,
      team_role: "member",
      confirmed_at: Time.current
    )

    # Create recent activities
    3.times do |i|
      Ahoy::Visit.create!(
        visit_token: "token-#{i}",
        visitor_token: "visitor-#{i}",
        user: direct_user,
        started_at: i.hours.ago
      )
    end

    get admin_super_root_path

    assert_response :success
    assert_match /dashboard/i, response.body

    # Verify all statistics are loaded
    assert_not_nil assigns(:total_users)
    assert_not_nil assigns(:direct_users)
    assert_not_nil assigns(:team_users)
    assert_not_nil assigns(:active_users)
    assert_not_nil assigns(:inactive_users)
    assert_not_nil assigns(:total_teams)
    assert_not_nil assigns(:active_teams)
    assert_not_nil assigns(:recent_teams)
    assert_not_nil assigns(:recent_users)
    assert_not_nil assigns(:recent_activities)

    # Verify counts are accurate
    assert assigns(:total_users) > 0
    assert assigns(:direct_users) > 0
    assert assigns(:team_users) > 0
    assert assigns(:inactive_users) > 0
  end

  # Weight: 5 - Edge case handling
  test "handles empty database gracefully" do
    # Delete all data except the logged-in super admin
    # First clear all foreign key dependencies
    User.where.not(id: @super_admin.id).update_all(team_id: nil, team_role: nil, enterprise_group_id: nil, enterprise_group_role: nil)
    Invitation.destroy_all
    Team.destroy_all
    EnterpriseGroup.destroy_all
    User.where.not(id: @super_admin.id).destroy_all

    get admin_super_root_path

    assert_response :success
    assert_equal 1, assigns(:total_users) # Only the super admin
    assert_equal 0, assigns(:total_teams)
    assert_equal 0, assigns(:active_teams)
    assert_equal 1, assigns(:direct_users) # Super admin is direct user
    assert_equal 0, assigns(:team_users)
    assert_empty assigns(:recent_teams)
    assert_empty assigns(:recent_users)
    assert_empty assigns(:recent_activities)
  end
end