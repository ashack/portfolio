require "test_helper"

class Users::StatusManagementServiceTest < ActiveSupport::TestCase
  def setup
    @super_admin = User.create!(
      email: "superadmin@example.com",
      password: "Password123!",
      system_role: "super_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )

    @site_admin = User.create!(
      email: "siteadmin@example.com",
      password: "Password123!",
      system_role: "site_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )

    @target_user = User.create!(
      email: "targetuser@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current,
      sign_in_count: 5
    )

    @request = OpenStruct.new(remote_ip: "127.0.0.1")
  end

  test "super admin can change user status to inactive" do
    service = Users::StatusManagementService.new(@super_admin, @target_user, "inactive", @request)

    result = service.call

    assert result.success?
    @target_user.reload
    assert_equal "inactive", @target_user.status
  end

  test "super admin can change user status to locked" do
    service = Users::StatusManagementService.new(@super_admin, @target_user, "locked", @request)

    result = service.call

    assert result.success?
    @target_user.reload
    assert_equal "locked", @target_user.status
  end

  test "super admin can reactivate user" do
    @target_user.update!(status: "inactive")

    service = Users::StatusManagementService.new(@super_admin, @target_user, "active", @request)

    result = service.call

    assert result.success?
    @target_user.reload
    assert_equal "active", @target_user.status
  end

  test "site admin can change user status" do
    service = Users::StatusManagementService.new(@site_admin, @target_user, "inactive", @request)

    result = service.call

    assert result.success?
    @target_user.reload
    assert_equal "inactive", @target_user.status
  end

  test "regular user cannot change user status" do
    regular_user = User.create!(
      email: "regular@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    service = Users::StatusManagementService.new(regular_user, @target_user, "inactive", @request)

    result = service.call

    assert_not result.success?
    assert_equal "Unauthorized", result.error
    @target_user.reload
    assert_equal "active", @target_user.status
  end

  test "team admin cannot change user status" do
    team = Team.create!(
      name: "Test Team",
      admin: @super_admin,
      created_by: @super_admin
    )

    team_admin = User.create!(
      email: "teamadmin@example.com",
      password: "Password123!",
      user_type: "invited",
      team: team,
      team_role: "admin",
      confirmed_at: Time.current
    )

    service = Users::StatusManagementService.new(team_admin, @target_user, "inactive", @request)

    result = service.call

    assert_not result.success?
    assert_equal "Unauthorized", result.error
  end

  test "rejects invalid status values" do
    service = Users::StatusManagementService.new(@super_admin, @target_user, "banned", @request)

    result = service.call

    assert_not result.success?
    assert_equal "Invalid status", result.error
  end

  test "logs status change with AuditLogService" do
    # Mock AuditLogService.log_status_change method
    called = false
    expected_args = nil

    AuditLogService.stub :log_status_change, ->(args) {
      called = true
      expected_args = args
    } do
      service = Users::StatusManagementService.new(@super_admin, @target_user, "inactive", @request)
      service.call
    end

    assert called, "AuditLogService.log_status_change should have been called"
    assert_equal @super_admin, expected_args[:admin_user]
    assert_equal @target_user, expected_args[:target_user]
    assert_equal "active", expected_args[:old_status]
    assert_equal "inactive", expected_args[:new_status]
    assert_equal @request, expected_args[:request]
  end

  test "sends notification when status changes" do
    # Mock UserNotificationService
    mock = Minitest::Mock.new
    mock.expect :call, true, [ @target_user, "active", "inactive", @super_admin ]

    UserNotificationService.stub :notify_status_change, mock do
      service = Users::StatusManagementService.new(@super_admin, @target_user, "inactive", @request)
      service.call
    end

    assert_mock mock
  end

  test "does not send notification when status stays the same" do
    @target_user.update!(status: "inactive")

    # Mock should not be called
    mock = Minitest::Mock.new

    UserNotificationService.stub :notify_status_change, mock do
      service = Users::StatusManagementService.new(@super_admin, @target_user, "inactive", @request)
      service.call
    end

    # Mock should have no expectations
    assert_mock mock
  end

  test "forces signout when deactivating user" do
    original_sign_in_count = @target_user.sign_in_count

    service = Users::StatusManagementService.new(@super_admin, @target_user, "inactive", @request)
    result = service.call

    assert result.success?
    @target_user.reload
    assert_equal 0, @target_user.sign_in_count
  end

  test "forces signout when locking user" do
    original_sign_in_count = @target_user.sign_in_count

    service = Users::StatusManagementService.new(@super_admin, @target_user, "locked", @request)
    result = service.call

    assert result.success?
    @target_user.reload
    assert_equal 0, @target_user.sign_in_count
  end

  test "does not force signout when activating user" do
    @target_user.update!(status: "inactive", sign_in_count: 5)

    service = Users::StatusManagementService.new(@super_admin, @target_user, "active", @request)
    result = service.call

    assert result.success?
    @target_user.reload
    assert_equal 5, @target_user.sign_in_count
  end

  test "handles request parameter being nil" do
    service = Users::StatusManagementService.new(@super_admin, @target_user, "inactive", nil)

    # Should not raise error
    assert_nothing_raised do
      result = service.call
      assert result.success?
    end
  end

  test "rolls back transaction on failure" do
    # Force a failure during update
    @target_user.stub :update!, ->(_) { raise ActiveRecord::RecordInvalid.new(@target_user) } do
      service = Users::StatusManagementService.new(@super_admin, @target_user, "inactive", @request)

      result = service.call

      assert_not result.success?
      assert result.error.present?

      # Status should not have changed
      @target_user.reload
      assert_equal "active", @target_user.status
    end
  end

  test "validates all valid statuses" do
    %w[active inactive locked].each do |status|
      # Reset user to different status first
      @target_user.update!(status: status == "active" ? "inactive" : "active")

      service = Users::StatusManagementService.new(@super_admin, @target_user, status, @request)
      result = service.call

      assert result.success?, "Status '#{status}' should be valid"
      @target_user.reload
      assert_equal status, @target_user.status
    end
  end

  test "result object has correct structure for success" do
    service = Users::StatusManagementService.new(@super_admin, @target_user, "inactive", @request)
    result = service.call

    assert_respond_to result, :success?
    assert result.success?
    assert_not_respond_to result, :error
  end

  test "result object has correct structure for failure" do
    service = Users::StatusManagementService.new(@super_admin, @target_user, "invalid_status", @request)
    result = service.call

    assert_respond_to result, :success?
    assert_respond_to result, :error
    assert_not result.success?
    assert_equal "Invalid status", result.error
  end
end
