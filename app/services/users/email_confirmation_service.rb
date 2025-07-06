class Users::EmailConfirmationService
  def initialize(admin_user, target_user, request = nil)
    @admin_user = admin_user
    @target_user = target_user
    @request = request
  end

  def call
    return failure("Unauthorized") unless can_confirm_email?
    return failure("User is already confirmed") if @target_user.confirmed?

    begin
      # Manually confirm the user
      @target_user.confirm

      if @target_user.confirmed?
        # Send notification using the notifier
        UserNotificationService.notify_account_confirmed(@target_user, @admin_user)

        # Log the admin action
        log_email_confirmation

        success
      else
        failure("Failed to confirm email address")
      end
    rescue StandardError => e
      Rails.logger.error "Email confirmation failed: #{e.message}"
      failure("Email confirmation failed: #{e.message}")
    end
  end

  private

  def can_confirm_email?
    @admin_user.super_admin?
  end

  def log_email_confirmation
    AuditLogService.log_email_confirm(
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
