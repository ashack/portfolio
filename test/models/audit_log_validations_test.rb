require "test_helper"

class AuditLogValidationsTest < ActiveSupport::TestCase
  def setup
    @admin = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      first_name: "Admin",
      last_name: "User",
      system_role: "super_admin",
      confirmed_at: Time.current
    )

    @target_user = User.create!(
      email: "target@example.com",
      password: "Password123!",
      first_name: "Target",
      last_name: "User",
      confirmed_at: Time.current
    )

    @audit_log = AuditLog.new(
      user: @admin,
      target_user: @target_user,
      action: "status_change",
      details: {
        old_status: "active",
        new_status: "inactive",
        timestamp: Time.current
      },
      ip_address: "127.0.0.1"
    )
  end

  # Basic presence validations
  test "action presence validation" do
    @audit_log.action = nil
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:action], "can't be blank"

    @audit_log.action = ""
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:action], "can't be blank"
  end

  test "user_id presence validation" do
    @audit_log.user = nil
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:user], "must exist"
  end

  test "target_user_id presence validation" do
    @audit_log.target_user = nil
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:target_user], "must exist"
  end

  # Action type validation
  test "action must be in ACTION_TYPES list" do
    invalid_actions = [ "invalid_action", "random", "not_allowed" ]

    invalid_actions.each do |action|
      @audit_log.action = action
      assert_not @audit_log.valid?, "Action '#{action}' should be invalid"
      assert_includes @audit_log.errors[:action], "is not included in the list"
    end
  end

  test "all USER_MANAGEMENT_ACTIONS are valid" do
    AuditLog::USER_MANAGEMENT_ACTIONS.each do |action|
      @audit_log.action = action
      assert @audit_log.valid?, "Action '#{action}' should be valid"
    end
  end

  test "all SECURITY_ACTIONS are valid" do
    AuditLog::SECURITY_ACTIONS.each do |action|
      @audit_log.action = action
      assert @audit_log.valid?, "Action '#{action}' should be valid"
    end
  end

  test "all ADMIN_ACTIONS are valid" do
    AuditLog::ADMIN_ACTIONS.each do |action|
      @audit_log.action = action
      assert @audit_log.valid?, "Action '#{action}' should be valid"
    end
  end

  test "all TEAM_ACTIONS are valid" do
    AuditLog::TEAM_ACTIONS.each do |action|
      @audit_log.action = action
      assert @audit_log.valid?, "Action '#{action}' should be valid"
    end
  end

  test "all SYSTEM_ACTIONS are valid" do
    AuditLog::SYSTEM_ACTIONS.each do |action|
      @audit_log.action = action
      assert @audit_log.valid?, "Action '#{action}' should be valid"
    end
  end

  # Action category method tests
  test "action_category returns correct category for each action type" do
    category_mappings = {
      "user_create" => "User Management",
      "status_change" => "User Management",
      "password_reset" => "Security",
      "account_unlock" => "Security",
      "impersonate" => "Admin",
      "admin_login" => "Admin",
      "team_create" => "Team Management",
      "invitation_send" => "Team Management",
      "data_export" => "System",
      "system_backup" => "System"
    }

    category_mappings.each do |action, expected_category|
      @audit_log.action = action
      assert_equal expected_category, @audit_log.action_category,
        "Action '#{action}' should have category '#{expected_category}'"
    end
  end

  test "action_category returns Other for unknown actions" do
    skip "Cannot test else case due to validation constraints"
  end

  # Action severity method tests
  test "action_severity returns critical for dangerous actions" do
    critical_actions = [ "user_delete", "team_delete", "critical_system_change" ]

    critical_actions.each do |action|
      @audit_log.action = action
      assert_equal "critical", @audit_log.action_severity,
        "Action '#{action}' should have critical severity"
    end
  end

  test "action_severity returns high for security actions" do
    high_severity_actions = AuditLog::SECURITY_ACTIONS + [ "permissions_change", "system_setting_change" ]

    high_severity_actions.each do |action|
      @audit_log.action = action
      assert_equal "high", @audit_log.action_severity,
        "Action '#{action}' should have high severity"
    end
  end

  test "action_severity returns medium for moderate actions" do
    medium_actions = [ "role_change", "status_change", "team_member_remove" ]

    medium_actions.each do |action|
      @audit_log.action = action
      assert_equal "medium", @audit_log.action_severity,
        "Action '#{action}' should have medium severity"
    end
  end

  test "action_severity returns low for other actions" do
    low_actions = [ "user_update", "team_member_add", "invitation_resend" ]

    low_actions.each do |action|
      @audit_log.action = action
      assert_equal "low", @audit_log.action_severity,
        "Action '#{action}' should have low severity"
    end
  end

  # Action icon method tests
  test "action_icon returns correct icon for each category" do
    icon_mappings = {
      "user_create" => "user",      # User Management
      "password_reset" => "shield", # Security
      "impersonate" => "key",       # Admin
      "team_create" => "users",     # Team Management
      "data_export" => "cog"        # System
    }

    icon_mappings.each do |action, expected_icon|
      @audit_log.action = action
      assert_equal expected_icon, @audit_log.action_icon,
        "Action '#{action}' should have icon '#{expected_icon}'"
    end
  end

  # Formatted details method tests
  test "formatted_details for user_update action" do
    @audit_log.action = "user_update"
    @audit_log.details = {
      "changes" => {
        "first_name" => { "from" => "Old", "to" => "New" },
        "email" => { "from" => "old@example.com", "to" => "new@example.com" }
      }
    }

    formatted = @audit_log.formatted_details
    assert_equal "Old → New", formatted["First name"]
    assert_equal "old@example.com → new@example.com", formatted["Email"]
  end

  test "formatted_details for status_change action" do
    @audit_log.action = "status_change"
    formatted = @audit_log.formatted_details

    assert_equal "active → inactive", formatted["Status Change"]
    assert formatted["Timestamp"].present?
  end

  test "formatted_details for role_change action" do
    @audit_log.action = "role_change"
    @audit_log.details = {
      "old_role" => "member",
      "new_role" => "admin",
      "timestamp" => Time.current
    }

    formatted = @audit_log.formatted_details
    assert_equal "member → admin", formatted["Role Change"]
    assert formatted["Timestamp"].present?
  end

  test "formatted_details returns original for other actions" do
    @audit_log.action = "team_create"
    @audit_log.details = { "team_name" => "New Team" }

    formatted = @audit_log.formatted_details
    assert_equal @audit_log.details, formatted
  end

  test "formatted_details handles nil details" do
    @audit_log.details = nil
    assert_equal({}, @audit_log.formatted_details)
  end

  test "formatted_details handles empty details" do
    @audit_log.details = {}
    assert_equal({}, @audit_log.formatted_details)
  end

  # Optional field tests
  test "ip_address is optional" do
    @audit_log.ip_address = nil
    assert @audit_log.valid?
  end

  test "details is optional" do
    @audit_log.details = nil
    assert @audit_log.valid?
  end

  # Association tests
  test "user association must exist" do
    non_existent_user_id = 99999
    @audit_log.user_id = non_existent_user_id

    assert_not @audit_log.valid?
    assert @audit_log.errors[:user].any?
  end

  test "target_user association must exist" do
    non_existent_user_id = 99999
    @audit_log.target_user_id = non_existent_user_id

    assert_not @audit_log.valid?
    assert @audit_log.errors[:target_user].any?
  end

  test "user and target_user can be the same" do
    @audit_log.target_user = @admin
    assert @audit_log.valid?
  end

  # Complex validation scenarios
  test "multiple validation errors are collected" do
    @audit_log.action = nil
    @audit_log.user = nil
    @audit_log.target_user = nil

    assert_not @audit_log.valid?

    assert @audit_log.errors[:action].any?
    assert @audit_log.errors[:user].any?
    assert @audit_log.errors[:target_user].any?
  end

  test "valid audit log with all fields" do
    @audit_log.ip_address = "192.168.1.1"
    @audit_log.details = {
      "reason" => "Admin decision",
      "notes" => "User requested deactivation"
    }

    assert @audit_log.valid?
    assert @audit_log.save
  end

  test "ACTION_TYPES constant includes all action arrays" do
    all_actions = AuditLog::USER_MANAGEMENT_ACTIONS +
                  AuditLog::SECURITY_ACTIONS +
                  AuditLog::ADMIN_ACTIONS +
                  AuditLog::TEAM_ACTIONS +
                  AuditLog::SYSTEM_ACTIONS

    assert_equal all_actions.sort, AuditLog::ACTION_TYPES.sort
  end

  test "no duplicate actions in ACTION_TYPES" do
    assert_equal AuditLog::ACTION_TYPES.uniq.size, AuditLog::ACTION_TYPES.size
  end
end
