class Users::StatusManagementService
  def initialize(admin_user, target_user, new_status, request = nil)
    @admin_user = admin_user
    @target_user = target_user
    @new_status = new_status
    @request = request
  end

  def call
    return failure("Unauthorized") unless can_manage_user_status?
    return failure("Invalid status") unless valid_status?

    @target_user.transaction do
      old_status = @target_user.status
      @target_user.update!(status: @new_status)

      log_status_change(old_status)
      send_notification_if_needed(old_status)
      force_signout_if_needed

      success
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def can_manage_user_status?
    @admin_user.super_admin? || @admin_user.site_admin?
  end

  def valid_status?
    %w[active inactive locked].include?(@new_status)
  end

  def log_status_change(old_status)
    AuditLogService.log_status_change(
      admin_user: @admin_user,
      target_user: @target_user,
      old_status: old_status,
      new_status: @new_status,
      request: @request
    )
  end

  def send_notification_if_needed(old_status)
    # Always send notification when status changes
    if old_status != @new_status
      UserNotificationService.notify_status_change(@target_user, old_status, @new_status, @admin_user)
    end
  end

  def force_signout_if_needed
    if @new_status != "active"
      # Force user logout by clearing all sessions
      @target_user.update_column(:sign_in_count, 0)
    end
  end

  def success
    OpenStruct.new(success?: true)
  end

  def failure(message)
    OpenStruct.new(success?: false, error: message)
  end
end
