require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  def setup
    @admin = User.new(
      email: "admin@example.com",
      password: "Password123!",
      first_name: "Admin",
      last_name: "User",
      system_role: "super_admin"
    )
    @admin.skip_confirmation!
    @admin.save!

    @target_user = User.new(
      email: "target@example.com",
      password: "Password123!",
      first_name: "Target",
      last_name: "User"
    )
    @target_user.skip_confirmation!
    @target_user.save!

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

  test "should be valid with valid attributes" do
    assert @audit_log.valid?
  end

  test "should require user" do
    @audit_log.user = nil
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:user], "must exist"
  end

  test "should require target_user" do
    @audit_log.target_user = nil
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:target_user], "must exist"
  end

  test "should require action" do
    @audit_log.action = nil
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:action], "can't be blank"
  end

  test "should only allow valid action types" do
    valid_actions = AuditLog::ACTION_TYPES

    valid_actions.sample(5).each do |action|
      @audit_log.action = action
      assert @audit_log.valid?, "#{action} should be valid"
    end

    @audit_log.action = "invalid_action"
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:action], "is not included in the list"
  end

  test "admin_name returns full name or email" do
    assert_equal "Admin User", @audit_log.admin_name

    @admin.first_name = nil
    @admin.last_name = nil
    @admin.save!

    assert_equal @admin.email, @audit_log.admin_name
  end

  test "target_user_name returns full name or email" do
    assert_equal "Target User", @audit_log.target_user_name

    @target_user.first_name = nil
    @target_user.last_name = nil
    @target_user.save!

    assert_equal @target_user.email, @audit_log.target_user_name
  end

  test "action_category returns correct category" do
    # User Management
    @audit_log.action = "user_create"
    assert_equal "User Management", @audit_log.action_category

    # Security
    @audit_log.action = "password_reset"
    assert_equal "Security", @audit_log.action_category

    # Admin
    @audit_log.action = "impersonate"
    assert_equal "Admin", @audit_log.action_category

    # Team Management
    @audit_log.action = "team_create"
    assert_equal "Team Management", @audit_log.action_category

    # System
    @audit_log.action = "data_export"
    assert_equal "System", @audit_log.action_category
  end

  test "action_severity returns correct severity level" do
    # Critical
    @audit_log.action = "user_delete"
    assert_equal "critical", @audit_log.action_severity

    # High
    @audit_log.action = "password_reset"
    assert_equal "high", @audit_log.action_severity

    # Medium
    @audit_log.action = "role_change"
    assert_equal "medium", @audit_log.action_severity

    # Low
    @audit_log.action = "user_update"
    assert_equal "low", @audit_log.action_severity
  end

  test "action_icon returns correct icon" do
    @audit_log.action = "user_create"
    assert_equal "user", @audit_log.action_icon

    @audit_log.action = "password_reset"
    assert_equal "shield", @audit_log.action_icon

    @audit_log.action = "impersonate"
    assert_equal "key", @audit_log.action_icon

    @audit_log.action = "team_create"
    assert_equal "users", @audit_log.action_icon

    @audit_log.action = "data_export"
    assert_equal "cog", @audit_log.action_icon
  end

  test "recent scope orders by created_at desc" do
    older_log = @audit_log.dup
    older_log.created_at = 1.day.ago
    older_log.save!

    @audit_log.save!

    recent_logs = AuditLog.recent
    assert_equal @audit_log, recent_logs.first
    assert_equal older_log, recent_logs.second
  end

  test "by_action scope filters by action" do
    @audit_log.save!

    other_log = AuditLog.create!(
      user: @admin,
      target_user: @target_user,
      action: "user_update"
    )

    status_changes = AuditLog.by_action("status_change")
    assert_includes status_changes, @audit_log
    assert_not_includes status_changes, other_log
  end

  test "by_admin scope filters by admin user" do
    @audit_log.save!

    other_admin = User.new(
      email: "other_admin@example.com",
      password: "Password123!",
      system_role: "site_admin"
    )
    other_admin.skip_confirmation!
    other_admin.save!

    other_log = AuditLog.create!(
      user: other_admin,
      target_user: @target_user,
      action: "status_change"
    )

    admin_logs = AuditLog.by_admin(@admin.id)
    assert_includes admin_logs, @audit_log
    assert_not_includes admin_logs, other_log
  end

  test "for_user scope filters by target user" do
    @audit_log.save!

    other_target = User.new(
      email: "other_target@example.com",
      password: "Password123!"
    )
    other_target.skip_confirmation!
    other_target.save!

    other_log = AuditLog.create!(
      user: @admin,
      target_user: other_target,
      action: "status_change"
    )

    user_logs = AuditLog.for_user(@target_user.id)
    assert_includes user_logs, @audit_log
    assert_not_includes user_logs, other_log
  end

  test "critical_actions scope returns critical and security actions" do
    @audit_log.action = "user_delete"
    @audit_log.save!

    security_log = AuditLog.create!(
      user: @admin,
      target_user: @target_user,
      action: "password_reset"
    )

    normal_log = AuditLog.create!(
      user: @admin,
      target_user: @target_user,
      action: "user_update"
    )

    critical = AuditLog.critical_actions
    assert_includes critical, @audit_log
    assert_includes critical, security_log
    assert_not_includes critical, normal_log
  end

  test "with_ip scope filters by IP address" do
    @audit_log.save!

    other_log = AuditLog.create!(
      user: @admin,
      target_user: @target_user,
      action: "status_change",
      ip_address: "192.168.1.1"
    )

    ip_logs = AuditLog.with_ip("127.0.0.1")
    assert_includes ip_logs, @audit_log
    assert_not_includes ip_logs, other_log
  end

  test "formatted_details formats status change details" do
    formatted = @audit_log.formatted_details

    assert_equal "active → inactive", formatted["Status Change"]
    assert formatted["Timestamp"].present?
  end

  test "formatted_details formats user update details" do
    @audit_log.action = "user_update"
    @audit_log.details = {
      "changes" => {
        "first_name" => { "from" => "Old", "to" => "New" },
        "last_name" => { "from" => "Name", "to" => "Name2" }
      }
    }

    formatted = @audit_log.formatted_details
    assert_equal "Old → New", formatted["First name"]
    assert_equal "Name → Name2", formatted["Last name"]
  end

  test "formatted_details formats role change details" do
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

  test "formatted_details returns empty hash when details nil" do
    @audit_log.details = nil
    assert_equal({}, @audit_log.formatted_details)
  end

  test "activity_summary returns correct statistics" do
    # Create multiple logs
    @audit_log.save!

    AuditLog.create!(
      user: @admin,
      target_user: @target_user,
      action: "user_delete"
    )

    other_admin = User.new(
      email: "other@example.com",
      password: "Password123!",
      system_role: "site_admin"
    )
    other_admin.skip_confirmation!
    other_admin.save!

    AuditLog.create!(
      user: other_admin,
      target_user: @target_user,
      action: "user_update"
    )

    summary = AuditLog.activity_summary(:today)

    assert_equal 3, summary[:total_actions]
    assert_equal 2, summary[:unique_admins]
    assert_equal 1, summary[:critical_actions]
    assert summary[:action_breakdown]["status_change"] >= 1
    assert summary[:category_breakdown]["User Management"] >= 1
  end

  test "admin_activity_report returns admin specific statistics" do
    @audit_log.save!

    AuditLog.create!(
      user: @admin,
      target_user: @target_user,
      action: "user_delete"
    )

    AuditLog.create!(
      user: @admin,
      target_user: @target_user,
      action: "user_update"
    )

    report = AuditLog.admin_activity_report(@admin, :today)

    assert_equal @admin, report[:admin]
    assert_equal 3, report[:total_actions]
    assert_equal 1, report[:critical_actions]
    assert report[:actions_by_type]["status_change"] >= 1
    assert report[:recent_activities].present?
  end

  test "time scopes filter correctly" do
    # Today
    today_log = @audit_log.dup
    today_log.save!

    # Yesterday
    yesterday_log = @audit_log.dup
    yesterday_log.created_at = 1.day.ago
    yesterday_log.save!

    # Last week
    last_week_log = @audit_log.dup
    last_week_log.created_at = 8.days.ago
    last_week_log.save!

    # Last month
    last_month_log = @audit_log.dup
    last_month_log.created_at = 32.days.ago
    last_month_log.save!

    today_logs = AuditLog.today
    assert_includes today_logs, today_log
    assert_not_includes today_logs, yesterday_log

    week_logs = AuditLog.this_week
    assert_includes week_logs, today_log
    assert_includes week_logs, yesterday_log
    assert_not_includes week_logs, last_week_log

    month_logs = AuditLog.this_month
    assert_includes month_logs, today_log
    assert_includes month_logs, yesterday_log
    assert_not_includes month_logs, last_month_log
  end
end
