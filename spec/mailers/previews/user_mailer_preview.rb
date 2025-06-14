class UserMailerPreview < ActionMailer::Preview
  def email_changed
    user = User.first || create_sample_user
    UserMailer.email_changed(user, "old@example.com")
  end

  def role_changed
    user = User.first || create_sample_user
    UserMailer.role_changed(user, "user", "site_admin")
  end

  def status_changed_to_active
    user = User.first || create_sample_user
    UserMailer.status_changed(user, "inactive", "active")
  end

  def status_changed_to_inactive
    user = User.first || create_sample_user
    UserMailer.status_changed(user, "active", "inactive")
  end

  def status_changed_to_locked
    user = User.first || create_sample_user
    UserMailer.status_changed(user, "active", "locked")
  end

  def reset_password_instructions
    user = User.first || create_sample_user
    UserMailer.reset_password_instructions(user, "sample-token-123")
  end

  def account_confirmed
    user = User.first || create_sample_user
    UserMailer.account_confirmed(user)
  end

  def account_unlocked
    user = User.first || create_sample_user
    UserMailer.account_unlocked(user)
  end

  private

  def create_sample_user
    User.new(
      email: "sample@example.com",
      first_name: "John",
      last_name: "Doe",
      system_role: "user",
      user_type: "direct",
      status: "active"
    )
  end
end
