class Users::ResendConfirmationService
  def initialize(admin_user, target_user, request = nil)
    @admin_user = admin_user
    @target_user = target_user
    @request = request
  end

  def call
    return failure("Unauthorized") unless can_resend_confirmation?
    return failure("User is already confirmed") if @target_user.confirmed?

    begin
      # Generate new confirmation token and send email
      @target_user.send_confirmation_instructions

      # Log the admin action
      log_resend_confirmation

      success
    rescue StandardError => e
      Rails.logger.error "Resend confirmation failed: #{e.message}"
      failure("Resend confirmation failed: #{e.message}")
    end
  end

  private

  def can_resend_confirmation?
    @admin_user.super_admin?
  end

  def log_resend_confirmation
    AuditLogService.log(
      admin_user: @admin_user,
      target_user: @target_user,
      action: "resend_confirmation",
      details: {
        timestamp: Time.current
      },
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
