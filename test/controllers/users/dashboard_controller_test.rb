require "test_helper"

class Users::DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @direct_user = sign_in_with(
      email: "directuser@example.com",
      user_type: "direct"
    )
  end

  # ========== CRITICAL TESTS (Weight 7-9) ==========
  
  # Weight: 9 - Critical access control (CR-U2)
  test "prevents access by non-direct users" do
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

  # Weight: 8 - Security requirement
  test "requires authentication" do
    sign_out @direct_user

    get user_dashboard_path
    assert_redirected_to new_user_session_path
  end

  # Weight: 7 - Revenue-related: payment processor handling
  test "handles payment processor states correctly" do
    # Test with active subscription
    mock_processor = Minitest::Mock.new
    mock_subscription = Struct.new(:status, :current_period_end).new("active", 30.days.from_now)
    mock_processor.expect :subscription, mock_subscription
    mock_processor.expect :present?, true

    @direct_user.stub :payment_processor, mock_processor do
      get user_dashboard_path
      assert_response :success
      assert_equal mock_subscription, assigns(:subscription)
    end

    # Test without payment processor
    @direct_user.stub :payment_processor, nil do
      get user_dashboard_path
      assert_response :success
      assert_nil assigns(:subscription)
    end
  end

  # ========== MEDIUM PRIORITY TESTS (Weight 5-6) ==========
  
  # Weight: 6 - Basic functionality and data loading
  test "loads dashboard with user data and recent activities" do
    # Create test activities
    5.times do |i|
      Ahoy::Visit.create!(
        visit_token: "token-#{i}",
        visitor_token: "visitor-#{i}",
        user: @direct_user,
        started_at: i.hours.ago
      )
    end

    get user_dashboard_path

    assert_response :success
    assert_match /dashboard/i, response.body
    assert_equal @direct_user, assigns(:user)
    assert_not_nil assigns(:recent_activities)
    assert_equal 5, assigns(:recent_activities).count
    
    # Verify ordering
    activities = assigns(:recent_activities)
    assert activities.first.started_at > activities.last.started_at,
      "Activities should be ordered by most recent first"
  end
end
