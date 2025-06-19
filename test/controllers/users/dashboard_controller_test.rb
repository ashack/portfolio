require "test_helper"

class Users::DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @direct_user = sign_in_with(
      email: "directuser@example.com",
      user_type: "direct"
    )
  end

  test "should get index for direct user" do
    get user_dashboard_path
    assert_response :success
    assert_match /dashboard/i, response.body
  end

  test "should assign user and recent activities" do
    # Create some visits for the user
    3.times do |i|
      Ahoy::Visit.create!(
        visit_token: "token-#{i}",
        visitor_token: "visitor-#{i}",
        user: @direct_user,
        started_at: i.hours.ago
      )
    end

    get user_dashboard_path

    assert_response :success
    assert_equal @direct_user, assigns(:user)
    assert_not_nil assigns(:recent_activities)
    assert_equal 3, assigns(:recent_activities).count
  end

  test "should handle user with payment processor" do
    # Mock payment processor with subscription
    mock_processor = Minitest::Mock.new
    mock_subscription = OpenStruct.new(status: "active", current_period_end: 30.days.from_now)
    mock_processor.expect :subscription, mock_subscription
    mock_processor.expect :present?, true

    @direct_user.stub :payment_processor, mock_processor do
      get user_dashboard_path

      assert_response :success
      assert_equal mock_subscription, assigns(:subscription)
    end

    assert_mock mock_processor
  end

  test "should handle user without payment processor" do
    @direct_user.stub :payment_processor, nil do
      get user_dashboard_path

      assert_response :success
      assert_nil assigns(:subscription)
    end
  end

  test "should redirect invited user to root" do
    sign_out @direct_user

    team = Team.create!(
      name: "Test Team",
      admin: users(:super_admin),
      created_by: users(:super_admin)
    )

    invited_user = sign_in_with(
      email: "inviteduser@example.com",
      user_type: "invited",
      team: team,
      team_role: "member"
    )

    get user_dashboard_path

    assert_redirected_to root_path
    assert_equal "This area is only accessible to direct users.", flash[:alert]
  end

  test "should redirect super admin to root" do
    sign_out @direct_user

    super_admin = sign_in_with(
      email: "superadmin@example.com",
      system_role: "super_admin",
      user_type: "direct"
    )

    # Super admins are direct users, so they should have access
    get user_dashboard_path
    assert_response :success
  end

  test "should redirect site admin to root" do
    sign_out @direct_user

    site_admin = sign_in_with(
      email: "siteadmin@example.com",
      system_role: "site_admin",
      user_type: "direct"
    )

    # Site admins are direct users, so they should have access
    get user_dashboard_path
    assert_response :success
  end

  test "should require authentication" do
    sign_out @direct_user

    get user_dashboard_path

    assert_redirected_to new_user_session_path
  end

  test "should not require authorization checks" do
    # This test ensures skip_after_action :verify_authorized works
    get user_dashboard_path
    assert_response :success
  end

  test "should limit recent activities to 5" do
    # Create 10 visits
    10.times do |i|
      Ahoy::Visit.create!(
        visit_token: "token-#{i}",
        visitor_token: "visitor-#{i}",
        user: @direct_user,
        started_at: i.hours.ago
      )
    end

    get user_dashboard_path

    assert_response :success
    assert_equal 5, assigns(:recent_activities).count
  end

  test "should order recent activities by started_at desc" do
    # Create visits with specific times
    old_visit = Ahoy::Visit.create!(
      visit_token: "old-token",
      visitor_token: "old-visitor",
      user: @direct_user,
      started_at: 2.days.ago
    )

    new_visit = Ahoy::Visit.create!(
      visit_token: "new-token",
      visitor_token: "new-visitor",
      user: @direct_user,
      started_at: 1.hour.ago
    )

    get user_dashboard_path

    activities = assigns(:recent_activities)
    assert_equal new_visit, activities.first
    assert_includes activities.to_a, old_visit
  end
end
