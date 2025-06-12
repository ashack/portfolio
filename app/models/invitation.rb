class Invitation < ApplicationRecord
  belongs_to :team
  belongs_to :invited_by, class_name: 'User'

  enum :role, { member: 0, admin: 1 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  
  validate :email_not_in_users_table
  validate :not_expired, on: :accept

  before_validation :generate_token, if: :new_record?
  before_validation :set_expiration, if: :new_record?

  scope :pending, -> { where(accepted_at: nil) }
  scope :active, -> { where('expires_at > ?', Time.current) }

  def to_param
    token
  end

  def expired?
    expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user_attributes = {})
    return false if expired? || accepted?

    User.transaction do
      user = User.create!(
        email: email,
        user_type: 'invited',
        team: team,
        team_role: role,
        status: 'active',
        **user_attributes
      )
      
      update!(accepted_at: Time.current)
      user
    end
  end

  private

  def email_not_in_users_table
    if User.exists?(email: email)
      errors.add(:email, 'already has an account')
    end
  end

  def not_expired
    if expired?
      errors.add(:base, 'Invitation has expired')
    end
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at = 7.days.from_now
  end
end