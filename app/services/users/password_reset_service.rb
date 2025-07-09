class Users::PasswordResetService
  def initialize(admin_user, target_user, request = nil)
    @admin_user = admin_user
    @target_user = target_user
    @request = request
  end

  def call
    return failure("Unauthorized") unless can_reset_password?
    return failure("Cannot reset your own password through admin panel") if resetting_own_password?

    begin
      # Generate password reset token using Devise
      raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)

      @target_user.reset_password_token = hashed_token
      @target_user.reset_password_sent_at = Time.current

      if @target_user.save(validate: false)
        # Send password reset email
        UserMailer.reset_password_instructions(@target_user, raw_token).deliver_now

        # Send notification about admin action
        UserNotificationService.notify_password_reset(@target_user, @admin_user)

        # Log the admin action
        log_password_reset

        success
      else
        failure("Failed to generate password reset token")
      end
    rescue StandardError => e
      Rails.logger.error "Password reset failed: #{e.message}"
      failure("Password reset failed: #{e.message}")
    end
  end

  private

  def can_reset_password?
    @admin_user.super_admin?
  end

  def resetting_own_password?
    @admin_user.id == @target_user.id
  end

  def log_password_reset
    AuditLogService.log_password_reset(
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
