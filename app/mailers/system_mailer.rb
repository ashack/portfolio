class SystemMailer < ApplicationMailer
  def announcement
    @user = params[:recipient]
    @title = params[:title]
    @message = params[:message]
    @priority = params[:priority]
    @announcement_type = params[:announcement_type]

    mail(
      to: @user.email,
      subject: "#{priority_emoji} #{@title}"
    )
  end

  private

  def priority_emoji
    case @priority
    when "critical"
      "🚨"
    when "high"
      "⚠️"
    when "medium"
      "📢"
    else
      "ℹ️"
    end
  end
end
