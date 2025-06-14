# Preview all emails at http://localhost:3000/rails/mailers/email_change_mailer_mailer
class EmailChangeMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/email_change_mailer_mailer/request_submitted
  def request_submitted
    EmailChangeMailer.request_submitted
  end

  # Preview this email at http://localhost:3000/rails/mailers/email_change_mailer_mailer/approved_notification
  def approved_notification
    EmailChangeMailer.approved_notification
  end

  # Preview this email at http://localhost:3000/rails/mailers/email_change_mailer_mailer/rejected_notification
  def rejected_notification
    EmailChangeMailer.rejected_notification
  end
end
