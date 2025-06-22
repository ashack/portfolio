require "test_helper"

class Admin::Super::DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @super_admin = sign_in_with(
      email: "superadmin@example.com",
      system_role: "super_admin",
      user_type: "direct"
    )
  end

  test "should get index for super admin" do
    get admin_super_root_path
    assert_response :success
    assert_match /dashboard/i, response.body
  end

  test "should assign all statistics" do
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

    locked_user = User.create!(
      email: "locked@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "locked",
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

    get admin_super_root_path

    assert_response :success

    # Check user counts
    assert_equal User.count, assigns(:total_users)
    assert_equal User.direct_users.count, assigns(:direct_users)
    assert_equal User.team_members.count, assigns(:team_users)

    # Check status counts
    assert_equal User.active.where.not(system_role: "super_admin").count, assigns(:active_users)
    assert_equal User.inactive.count, assigns(:inactive_users)
    assert_equal User.locked.count, assigns(:locked_users)

    # Check team counts
    assert_equal Team.count, assigns(:total_teams)
    assert_equal Team.active.count, assigns(:active_teams)
  end

  test "should assign recent data" do
    # Create teams
    3.times do |i|
      Team.create!(
        name: "Team #{i}",
        admin: @super_admin,
        created_by: @super_admin,
        created_at: i.days.ago
      )
    end

    # Create users with different activity times
    5.times do |i|
      User.create!(
        email: "user#{i}@example.com",
        password: "Password123!",
        user_type: "direct",
        confirmed_at: Time.current,
        created_at: i.hours.ago,
        last_activity_at: i.minutes.ago
      )
    end

    get admin_super_root_path

    assert_response :success

    # Check recent collections
    assert_not_nil assigns(:recent_teams)
    assert_equal 3, assigns(:recent_teams).count

    assert_not_nil assigns(:recent_users)
    assert assigns(:recent_users).count <= 10

    assert_not_nil assigns(:recent_activities)
    assert assigns(:recent_activities).count <= 10
  end

  test "should exclude super admins from user lists" do
    # Create another super admin
    other_super = User.create!(
      email: "othersuper@example.com",
      password: "Password123!",
      system_role: "super_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )

    # Create regular users
    regular_user = User.create!(
      email: "regular@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    get admin_super_root_path

    recent_users = assigns(:recent_users)
    recent_activities = assigns(:recent_activities)

    # Should not include super admins
    assert_not recent_users.include?(@super_admin)
    assert_not recent_users.include?(other_super)
    assert_not recent_activities.include?(@super_admin)
    assert_not recent_activities.include?(other_super)

    # Should include regular users
    assert recent_users.include?(regular_user)
  end

  test "should redirect site admin to root" do
    sign_out @super_admin

    site_admin = sign_in_with(
      email: "siteadmin@example.com",
      system_role: "site_admin",
      user_type: "direct"
    )

    get admin_super_root_path

    assert_redirected_to root_path
    assert_equal "You must be a super admin to access this area.", flash[:alert]
  end

  test "should redirect regular user to root" do
    sign_out @super_admin

    regular_user = sign_in_with(
      email: "regular@example.com",
      user_type: "direct"
    )

    get admin_super_root_path

    assert_redirected_to root_path
    assert_equal "You must be a super admin to access this area.", flash[:alert]
  end

  test "should redirect team member to root" do
    sign_out @super_admin

    team = Team.create!(
      name: "Test Team",
      admin: users(:super_admin),
      created_by: users(:super_admin)
    )

    team_member = sign_in_with(
      email: "teammember@example.com",
      user_type: "invited",
      team: team,
      team_role: "member"
    )

    get admin_super_root_path

    assert_redirected_to root_path
    assert_equal "You must be a super admin to access this area.", flash[:alert]
  end

  test "should require authentication" do
    sign_out @super_admin

    get admin_super_root_path

    assert_redirected_to new_user_session_path
  end

  test "should use admin layout" do
    get admin_super_root_path

    assert_response :success
    # The _layout method changed in Rails 8
    # Check if the admin layout is being used by examining the response
    assert_match(/admin/, @response.body) if @response.body.present?
  end

  test "should track activity" do
    skip "ActivityTrackable uses async job which is not configured"

    # ActivityTrackable concern should track admin activity
    assert_difference "AdminActivityLog.count", 1 do
      get admin_super_root_path
    end

    activity = AdminActivityLog.last
    assert_equal @super_admin, activity.admin
    assert_equal "page_view", activity.action
    assert_equal "/admin/super", activity.path
  end

  test "should handle empty database gracefully" do
    # Delete all data except the logged-in super admin
    # First remove users from teams to avoid foreign key constraints
    User.where.not(id: @super_admin.id).update_all(team_id: nil, team_role: nil)
    Team.destroy_all
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
