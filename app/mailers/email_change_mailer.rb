class EmailChangeMailer < ApplicationMailer
  def request_submitted(email_change_request)
    @email_change_request = email_change_request
    @user = email_change_request.user

    mail(
      to: @user.email,
      subject: "Email Change Request Submitted"
    )
  end

  def approved_notification(email_change_request)
    @email_change_request = email_change_request
    @user = email_change_request.user
    @approved_by = email_change_request.approved_by

    mail(
      to: @email_change_request.new_email,
      subject: "Email Change Request Approved"
    )
  end

  def rejected_notification(email_change_request)
    @email_change_request = email_change_request
    @user = email_change_request.user
    @rejected_by = email_change_request.approved_by

    mail(
      to: @user.email,
      subject: "Email Change Request Rejected"
    )
  end
end
