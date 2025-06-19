require "test_helper"

class AuditLogServiceTest < ActiveSupport::TestCase
  def setup
    @admin_user = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      system_role: "super_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )

    @target_user = User.create!(
      email: "target@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    @request = OpenStruct.new(
      remote_ip: "127.0.0.1",
      user_agent: "Mozilla/5.0 Test Browser",
      session: OpenStruct.new(id: OpenStruct.new(public_id: "session123"))
    )
  end

  test "log creates audit log with basic params" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log(
        admin_user: @admin_user,
        target_user: @target_user,
        action: "user_update",
        details: { test: "data" },
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal @admin_user, audit_log.user
    assert_equal @target_user, audit_log.target_user
    assert_equal "user_update", audit_log.action
    assert_equal({ "test" => "data" }, audit_log.details)
    assert_equal "127.0.0.1", audit_log.ip_address
    assert_equal "Mozilla/5.0 Test Browser", audit_log.user_agent
  end

  test "log handles nil request gracefully" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log(
        admin_user: @admin_user,
        target_user: @target_user,
        action: "user_update",
        request: nil
      )
    end

    audit_log = AuditLog.last
    assert_nil audit_log.ip_address
    assert_nil audit_log.user_agent
  end

  test "log rescues and logs invalid records" do
    # Create invalid action
    assert_no_difference "AuditLog.count" do
      # Capture Rails.logger output
      logged_messages = []
      Rails.logger.stub :error, ->(msg) { logged_messages << msg } do
        AuditLogService.log(
          admin_user: @admin_user,
          target_user: @target_user,
          action: "invalid_action",
          request: @request
        )
      end

      assert logged_messages.any? { |msg| msg.include?("Failed to create audit log") }
      assert logged_messages.any? { |msg| msg.include?("Details: admin_user=#{@admin_user.id}") }
    end
  end

  test "log_user_update creates audit log with changes" do
    changes = {
      "first_name" => { "from" => "Old", "to" => "New" },
      "email" => { "from" => "old@example.com", "to" => "new@example.com" }
    }

    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_user_update(
        admin_user: @admin_user,
        target_user: @target_user,
        changes: changes,
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "user_update", audit_log.action
    assert_equal changes, audit_log.details["changes"]
    assert_not_nil audit_log.details["timestamp"]
  end

  test "log_user_update skips when changes are empty" do
    assert_no_difference "AuditLog.count" do
      AuditLogService.log_user_update(
        admin_user: @admin_user,
        target_user: @target_user,
        changes: {},
        request: @request
      )
    end
  end

  test "log_status_change creates proper audit log" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_status_change(
        admin_user: @admin_user,
        target_user: @target_user,
        old_status: "active",
        new_status: "inactive",
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "status_change", audit_log.action
    assert_equal "active", audit_log.details["old_status"]
    assert_equal "inactive", audit_log.details["new_status"]
    assert_not_nil audit_log.details["timestamp"]
  end

  test "log_role_change creates proper audit log" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_role_change(
        admin_user: @admin_user,
        target_user: @target_user,
        old_role: "member",
        new_role: "admin",
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "role_change", audit_log.action
    assert_equal "member", audit_log.details["old_role"]
    assert_equal "admin", audit_log.details["new_role"]
  end

  test "log_password_reset creates proper audit log" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_password_reset(
        admin_user: @admin_user,
        target_user: @target_user,
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "password_reset", audit_log.action
    assert_not_nil audit_log.details["timestamp"]
  end

  test "log_email_confirm creates proper audit log" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_email_confirm(
        admin_user: @admin_user,
        target_user: @target_user,
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "email_confirm", audit_log.action
  end

  test "log_account_unlock creates proper audit log" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_account_unlock(
        admin_user: @admin_user,
        target_user: @target_user,
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "account_unlock", audit_log.action
  end

  test "log_impersonate creates proper audit log" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_impersonate(
        admin_user: @admin_user,
        target_user: @target_user,
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "impersonate", audit_log.action
  end

  test "log_admin_login creates self-referential log" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_admin_login(
        admin_user: @admin_user,
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "admin_login", audit_log.action
    assert_equal @admin_user, audit_log.user
    assert_equal @admin_user, audit_log.target_user
    assert_equal "session123", audit_log.details["session_id"]
  end

  test "log_admin_logout calculates session duration" do
    # Create a login record first
    AuditLogService.log_admin_login(
      admin_user: @admin_user,
      request: @request
    )

    # Wait a moment
    sleep 0.1

    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_admin_logout(
        admin_user: @admin_user,
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "admin_logout", audit_log.action
    assert_not_nil audit_log.details["session_duration"]
    # Check if session_duration exists and has correct structure
    if audit_log.details["session_duration"]
      assert audit_log.details["session_duration"]["seconds"] >= 0
      assert_not_nil audit_log.details["session_duration"]["formatted"]
    end
  end

  test "log_admin_logout handles no previous login" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_admin_logout(
        admin_user: @admin_user,
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_nil audit_log.details["session_duration"]
  end

  test "log_team_action creates log with team details" do
    team = Team.create!(
      name: "Test Team",
      admin: @admin_user,
      created_by: @admin_user
    )

    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_team_action(
        admin_user: @admin_user,
        team: team,
        action: "team_create",
        details: { custom: "data" },
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "team_create", audit_log.action
    assert_equal team.id, audit_log.details["team_id"]
    assert_equal team.name, audit_log.details["team_name"]
    assert_equal "data", audit_log.details["custom"]
  end

  test "log_invitation_action creates log with invitation details" do
    team = Team.create!(
      name: "Test Team",
      admin: @admin_user,
      created_by: @admin_user
    )

    invitation = Invitation.create!(
      team: team,
      email: "invitee@example.com",
      invited_by: @admin_user,
      role: "member"
    )

    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_invitation_action(
        admin_user: @admin_user,
        invitation: invitation,
        action: "invitation_send",
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "invitation_send", audit_log.action
    assert_equal invitation.email, audit_log.details["invitation_email"]
    assert_equal team.id, audit_log.details["team_id"]
    assert_equal team.name, audit_log.details["team_name"]
    assert_equal "member", audit_log.details["role"]
  end

  test "log_system_action creates self-referential log" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_system_action(
        admin_user: @admin_user,
        action: "system_backup",
        details: { backup_type: "full" },
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "system_backup", audit_log.action
    assert_equal @admin_user, audit_log.user
    assert_equal @admin_user, audit_log.target_user
    assert_equal "full", audit_log.details["backup_type"]
  end

  test "log_bulk_operation creates log with operation details" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_bulk_operation(
        admin_user: @admin_user,
        operation: "disable_inactive_users",
        affected_count: 25,
        details: { criteria: "last_login > 90 days" },
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "bulk_operation", audit_log.action
    assert_equal "disable_inactive_users", audit_log.details["operation"]
    assert_equal 25, audit_log.details["affected_count"]
    assert_equal "last_login > 90 days", audit_log.details["criteria"]
  end

  test "log_security_event creates log with security flag" do
    assert_difference "AuditLog.count", 1 do
      AuditLogService.log_security_event(
        admin_user: @admin_user,
        target_user: @target_user,
        event_type: "security_lock",
        details: { reason: "multiple failed login attempts" },
        request: @request
      )
    end

    audit_log = AuditLog.last
    assert_equal "security_lock", audit_log.action
    assert_equal true, audit_log.details["security_event"]
    assert_equal "multiple failed login attempts", audit_log.details["reason"]
  end

  test "all methods include timestamp in details" do
    methods_to_test = [
      -> { AuditLogService.log_status_change(admin_user: @admin_user, target_user: @target_user, old_status: "active", new_status: "inactive") },
      -> { AuditLogService.log_role_change(admin_user: @admin_user, target_user: @target_user, old_role: "member", new_role: "admin") },
      -> { AuditLogService.log_password_reset(admin_user: @admin_user, target_user: @target_user) },
      -> { AuditLogService.log_email_confirm(admin_user: @admin_user, target_user: @target_user) },
      -> { AuditLogService.log_account_unlock(admin_user: @admin_user, target_user: @target_user) },
      -> { AuditLogService.log_impersonate(admin_user: @admin_user, target_user: @target_user) }
    ]

    methods_to_test.each do |method|
      method.call
      audit_log = AuditLog.last
      assert_not_nil audit_log.details["timestamp"], "Timestamp missing for #{audit_log.action}"
      assert_in_delta Time.current, Time.parse(audit_log.details["timestamp"]), 5.seconds
    end
  end
end
