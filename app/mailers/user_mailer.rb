class UserMailer < ApplicationMailer
  def reset_password_instructions(user, token)
    @user = user
    @token = token
    @reset_password_url = edit_user_password_url(reset_password_token: @token)

    mail(
      to: @user.email,
      subject: "Reset your password - Admin initiated"
    )
  end

  def email_changed(user, old_email)
    @user = user
    @old_email = old_email
    @new_email = user.email

    # Send to both old and new email addresses
    mail(
      to: [ @old_email, @new_email ],
      subject: "Your email address has been updated"
    )
  end

  def role_changed(user, old_role, new_role)
    @user = user
    @old_role = old_role.humanize
    @new_role = new_role.humanize

    mail(
      to: @user.email,
      subject: "Your account role has been updated"
    )
  end

  def status_changed(user, old_status, new_status)
    @user = user
    @old_status = old_status.humanize
    @new_status = new_status.humanize

    mail(
      to: @user.email,
      subject: "Your account status has been updated"
    )
  end

  def account_confirmed(user)
    @user = user

    mail(
      to: @user.email,
      subject: "Your account has been confirmed"
    )
  end

  def account_unlocked(user)
    @user = user

    mail(
      to: @user.email,
      subject: "Your account has been unlocked"
    )
  end
end
