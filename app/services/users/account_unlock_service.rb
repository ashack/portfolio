class Users::AccountUnlockService
  def initialize(admin_user, target_user, request = nil)
    @admin_user = admin_user
    @target_user = target_user
    @request = request
  end

  def call
    return failure("Unauthorized") unless can_unlock_account?
    return failure("Account is not locked") unless account_locked?

    begin
      # Use Devise's unlock_access! method which properly clears all lock fields
      @target_user.unlock_access!

      # Also ensure failed_attempts is reset to 0
      @target_user.update_column(:failed_attempts, 0) if @target_user.failed_attempts > 0

      # Send notification using the notifier
      UserNotificationService.notify_account_unlocked(@target_user, @admin_user, "Account security review completed")

      # Log the admin action
      log_account_unlock

      success
    rescue StandardError => e
      Rails.logger.error "Account unlock failed: #{e.message}"
      failure("Account unlock failed: #{e.message}")
    end
  end

  private

  def can_unlock_account?
    @admin_user.super_admin?
  end

  def account_locked?
    @target_user.access_locked?
  end

  def log_account_unlock
    AuditLogService.log_account_unlock(
      admin_user: @admin_user,
      target_user: @target_user,
      request: @request
    )
  end

  def success
    OpenStruct.new(success?: true)
  end

  def failure(message)
    OpenStruct.new(success?: false, error: message)
  end
end
