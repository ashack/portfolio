class Invitation < ApplicationRecord
  belongs_to :team, optional: true
  belongs_to :invitable, polymorphic: true, optional: true
  belongs_to :invited_by, class_name: "User"

  enum :role, { member: 0, admin: 1 }
  enum :invitation_type, { team: 0, enterprise: 1 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :invitation_type, presence: true

  # Ensure proper associations based on invitation type
  validates :team_id, presence: true, if: :team_invitation?
  validates :invitable, presence: true, if: :enterprise_invitation?

  validate :email_not_in_users_table
  validate :not_expired, on: :accept

  before_validation :normalize_email
  before_validation :generate_token, if: :new_record?
  before_validation :set_expiration, if: :new_record?
  before_validation :set_invitable_from_team, if: :team_invitation?

  scope :pending, -> { where(accepted_at: nil) }
  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :for_teams, -> { where(invitation_type: 'team') }
  scope :for_enterprise, -> { where(invitation_type: 'enterprise') }

  def to_param
    token
  end

  def expired?
    expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def pending?
    !accepted?
  end

  def accept!(user_attributes = {})
    return false if expired? || accepted?

    User.transaction do
      user = if team_invitation?
        User.create!(
          email: email,
          user_type: "invited",
          team: team,
          team_role: role,
          status: "active",
          **user_attributes
        )
      elsif enterprise_invitation?
        # For enterprise invitations, create enterprise user
        enterprise_group = invitable
        User.create!(
          email: email,
          user_type: "enterprise",
          enterprise_group: enterprise_group,
          enterprise_group_role: role, # admin role for enterprise
          status: "active",
          **user_attributes
        )
      end

      update!(accepted_at: Time.current)
      
      # Update enterprise group admin if this is an enterprise admin invitation
      if enterprise_invitation? && admin?
        invitable.update!(admin: user)
      end
      
      user
    end
  end

  def team_invitation?
    invitation_type == 'team' || team.present?
  end

  def enterprise_invitation?
    invitation_type == 'enterprise'
  end

  private

  def set_invitable_from_team
    if team.present? && invitable.blank?
      self.invitable = team
    end
  end

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def email_not_in_users_table
    return unless email.present?

    if User.exists?(email: email.downcase)
      errors.add(:email, "already has an account")
    end
  end

  def not_expired
    if expired?
      errors.add(:base, "Invitation has expired")
    end
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at = 7.days.from_now
  end
end
