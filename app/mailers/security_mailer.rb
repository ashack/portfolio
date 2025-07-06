class SecurityMailer < ApplicationMailer
  def security_alert
    @user = params[:recipient]
    @alert_type = params[:alert_type]
    @ip_address = params[:ip_address]
    @location = params[:location]
    @details = params[:details]
    @timestamp = Time.current

    mail(
      to: @user.email,
      subject: "🚨 Security Alert: #{@alert_type&.humanize}",
      priority: "high"
    )
  end
end
