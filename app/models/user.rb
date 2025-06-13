class User < ApplicationRecord
  include Pay::Billable # For individual user billing

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :trackable, :lockable

  belongs_to :team, optional: true
  has_many :created_teams, class_name: "Team", foreign_key: "created_by_id"
  has_many :administered_teams, class_name: "Team", foreign_key: "admin_id"
  has_many :sent_invitations, class_name: "Invitation", foreign_key: "invited_by_id"
  has_many :ahoy_visits, class_name: "Ahoy::Visit"

  enum :system_role, { user: 0, site_admin: 1, super_admin: 2 }
  enum :user_type, { direct: 0, invited: 1 }
  enum :status, { active: 0, inactive: 1, locked: 2 }
  enum :team_role, { member: 0, admin: 1 }

  validates :user_type, presence: true
  validates :status, presence: true

  # Validation: direct users cannot have team associations
  validates :team_id, absence: true, if: :direct?
  validates :team_role, absence: true, if: :direct?

  # Validation: invited users must have team associations
  validates :team_id, presence: true, if: :invited?
  validates :team_role, presence: true, if: :invited?

  scope :active, -> { where(status: "active") }
  scope :direct_users, -> { where(user_type: "direct") }
  scope :team_members, -> { where(user_type: "invited") }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def can_sign_in?
    active?
  end

  def team_admin?
    invited? && team_role == "admin"
  end

  def team_member?
    invited? && team_role == "member"
  end

  # Override Devise method to check status
  def active_for_authentication?
    # First check Devise's built-in checks (including lockable)
    return false unless super
    # Then check our custom status
    can_sign_in?
  end

  def inactive_message
    # Check Devise's lockable mechanism first
    if access_locked?
      :locked
    # Check our custom locked status
    elsif locked?
      :locked
    # Check our custom inactive status
    elsif inactive?
      :account_inactive
    else
      super
    end
  end
end
