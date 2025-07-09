class EmailChangeRequest < ApplicationRecord
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2, expired: 3 }

  validates :new_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :reason, presence: true, length: { minimum: 10, maximum: 500 }
  validates :token, presence: true, uniqueness: true
  validates :requested_at, presence: true

  validate :new_email_is_different
  validate :new_email_not_taken
  validate :user_has_no_pending_request, on: :create

  before_validation :generate_token, if: :new_record?
  before_validation :set_requested_at, if: :new_record?
  after_create :send_request_notification

  scope :recent, -> { order(requested_at: :desc) }
  scope :for_approval, -> { pending.order(requested_at: :asc) }
  scope :by_user, ->(user) { where(user: user) }

  # Expire requests after 30 days
  EXPIRY_DAYS = 30

  def to_param
    token
  end

  def expired?
    requested_at < EXPIRY_DAYS.days.ago
  end

  def can_be_approved_by?(admin_user)
    return false unless pending?
    return false if expired?

    # Super admins can approve any request
    return true if admin_user.super_admin?

    # Team admins can approve requests from their team members
    if admin_user.team_admin? && user.team_id == admin_user.team_id
      return true
    end

    false
  end

  def approve!(admin_user, notes: nil)
    return false unless can_be_approved_by?(admin_user)

    ApplicationRecord.transaction do
      # Update the user's email
      old_email = user.email

      # Set authorization flag to bypass email change protection
      Thread.current[:email_change_authorized] = true
      begin
        user.update!(email: new_email, confirmed_at: Time.current)
      ensure
        # Always clear the flag
        Thread.current[:email_change_authorized] = false
      end

      # Update the request
      self.update!(
        status: :approved,
        approved_by: admin_user,
        approved_at: Time.current,
        notes: notes
      )

      # Log the action
      AuditLogService.log(
        admin_user: admin_user,
        target_user: user,
        action: "email_change_approved",
        details: {
          old_email: old_email,
          new_email: new_email,
          request_id: id,
          reason: reason
        }
      )

      # Send security notification to old email
      EmailChangeSecurityNotifier.with(
        user: user,
        old_email: old_email,
        new_email: new_email,
        changed_at: Time.current
      ).deliver(user)

      # Send approval notification
      EmailChangeRequestNotifier.with(
        email_change_request: self,
        action: "approved",
        admin: admin_user
      ).deliver(user)

      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def reject!(admin_user, notes:)
    return false unless can_be_approved_by?(admin_user)

    ApplicationRecord.transaction do
      self.update!(
        status: :rejected,
        approved_by: admin_user,
        approved_at: Time.current,
        notes: notes
      )

      # Log the action
      AuditLogService.log(
        admin_user: admin_user,
        target_user: user,
        action: "email_change_rejected",
        details: {
          current_email: user.email,
          requested_email: new_email,
          request_id: id,
          reason: reason,
          rejection_reason: notes
        }
      )

      # Send rejection notification
      EmailChangeRequestNotifier.with(
        email_change_request: self,
        action: "rejected",
        admin: admin_user
      ).deliver(user)

      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def self.expire_old_requests
    pending.where("requested_at < ?", EXPIRY_DAYS.days.ago).update_all(status: :expired)
  end

  def time_ago_in_words
    ActionController::Base.helpers.time_ago_in_words(requested_at)
  end

  def status_badge_class
    case status
    when "pending"
      "bg-yellow-100 text-yellow-800"
    when "approved"
      "bg-green-100 text-green-800"
    when "rejected"
      "bg-red-100 text-red-800"
    when "expired"
      "bg-gray-100 text-gray-800"
    end
  end

  private

  def new_email_is_different
    if new_email == user&.email
      errors.add(:new_email, "must be different from current email")
    end
  end

  def new_email_not_taken
    if User.exists?(email: new_email)
      errors.add(:new_email, "is already taken by another user")
    end
  end

  def user_has_no_pending_request
    if user&.email_change_requests&.pending&.exists?
      errors.add(:base, "You already have a pending email change request")
    end
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_requested_at
    self.requested_at = Time.current
  end

  def send_request_notification
    EmailChangeRequestNotifier.with(
      email_change_request: self,
      action: "submitted"
    ).deliver(user)
  end
end
