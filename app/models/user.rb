class User < ApplicationRecord
  pay_customer # For individual user billing

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :trackable, :lockable

  belongs_to :team, optional: true
  has_many :created_teams, class_name: "Team", foreign_key: "created_by_id"
  has_many :administered_teams, class_name: "Team", foreign_key: "admin_id"
  has_many :sent_invitations, class_name: "Invitation", foreign_key: "invited_by_id"
  has_many :ahoy_visits, class_name: "Ahoy::Visit"
  has_many :audit_logs, foreign_key: "user_id", dependent: :destroy
  has_many :target_audit_logs, class_name: "AuditLog", foreign_key: "target_user_id", dependent: :destroy
  has_many :email_change_requests, dependent: :destroy
  has_many :approved_email_changes, class_name: "EmailChangeRequest", foreign_key: "approved_by_id"

  enum :system_role, { user: 0, site_admin: 1, super_admin: 2 }
  enum :user_type, { direct: 0, invited: 1 }
  enum :status, { active: 0, inactive: 1, locked: 2 }
  enum :team_role, { member: 0, admin: 1 }

  validates :user_type, presence: true
  validates :status, presence: true

  # Enhanced field validations with helpful messages
  validates :first_name, length: { maximum: 50, message: "must be 50 characters or less" },
                        format: { with: /\A[a-zA-Z\s\-'\.]*\z/, message: "can only contain letters, spaces, hyphens, apostrophes, and periods" },
                        allow_blank: true

  validates :last_name, length: { maximum: 50, message: "must be 50 characters or less" },
                       format: { with: /\A[a-zA-Z\s\-'\.]*\z/, message: "can only contain letters, spaces, hyphens, apostrophes, and periods" },
                       allow_blank: true

  validates :email, presence: { message: "is required" },
                   uniqueness: { case_sensitive: false, message: "is already taken" },
                   format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  # Custom validation to check email conflicts with pending invitations
  validate :email_not_in_pending_invitations, if: :email_changed?

  # Core business rule: prevent user_type changes after creation
  validate :user_type_cannot_be_changed, if: :user_type_changed?

  # Validation: direct users cannot have team associations
  validates :team_id, absence: { message: "cannot be set for direct users" }, if: :direct?
  validates :team_role, absence: { message: "cannot be set for direct users" }, if: :direct?

  # Validation: invited users must have team associations
  validates :team_id, presence: { message: "is required for team members" }, if: :invited?
  validates :team_role, presence: { message: "is required for team members" }, if: :invited?

  # Custom validation to ensure team constraints remain intact
  validate :team_constraints_remain_intact, if: :team_association_changed?

  # Email normalization callback
  before_validation :normalize_email

  # Custom validation to prevent system role changes in certain contexts
  validate :system_role_change_allowed, if: :system_role_changed?

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

  # Helper method to check if account needs unlocking
  def needs_unlock?
    access_locked? && (failed_attempts > 0 || locked_at.present?)
  end

  # Helper method to get lock status for admin display
  def lock_status
    if access_locked?
      if failed_attempts > 0
        "Locked (#{failed_attempts} failed attempts)"
      else
        "Locked by admin"
      end
    else
      "Unlocked"
    end
  end

  private

  # Normalize email to lowercase for consistency
  def normalize_email
    self.email = email&.downcase&.strip
  end

  # Validation method to check for email conflicts with pending invitations
  def email_not_in_pending_invitations
    return unless email.present?

    # Check if the new email conflicts with any pending invitations
    pending_invitation = Invitation.pending.active.find_by(email: email.downcase)

    if pending_invitation
      errors.add(:email, "conflicts with pending team invitation for #{pending_invitation.team.name}")
    end
  end

  # Core business rule: user_type cannot be changed after user creation
  def user_type_cannot_be_changed
    return if new_record? # Allow setting user_type during creation

    old_type = user_type_was
    new_type = user_type

    errors.add(:user_type, "cannot be changed from '#{old_type}' to '#{new_type}' - this is a core business rule")
  end

  # Helper method to detect team association changes
  def team_association_changed?
    team_id_changed? || team_role_changed?
  end

  # Comprehensive team constraint validation
  def team_constraints_remain_intact
    return if new_record? # Allow setting team associations during creation

    # Validate team existence
    validate_team_exists if team_id.present?

    # Validate team role transitions
    validate_team_role_transitions if team_role_changed?

    # Validate team admin constraints
    validate_team_admin_constraints if team_role_changed? || team_id_changed?

    # Validate team member limits
    validate_team_member_limits if team_id_changed?

    # Validate direct user constraints
    validate_direct_user_team_constraints if user_type == "direct"
  end

  def validate_team_exists
    unless Team.exists?(team_id)
      errors.add(:team_id, "references a team that doesn't exist")
    end
  end

  def validate_team_role_transitions
    old_role = team_role_was
    new_role = team_role

    # Prevent invalid role transitions that could break team structure
    if old_role == "admin" && new_role == "member"
      # Check if this is the only admin for the team
      if team&.users&.where(team_role: "admin")&.where&.not(id: id)&.count == 0
        errors.add(:team_role, "cannot be changed from admin to member - team must have at least one admin")
      end
    end
  end

  def validate_team_admin_constraints
    # Ensure team admin assignments are valid
    if team_role == "admin" && team.present?
      # Check if the team's admin_id should be updated
      if team.admin_id != id && team.admin_id == id_was
        errors.add(:team_role, "cannot be changed - you are the designated team admin")
      end
    end
  end

  def validate_team_member_limits
    return unless team_id.present? && team_id_changed?

    new_team = Team.find_by(id: team_id)
    return unless new_team

    current_member_count = new_team.users.count
    if current_member_count >= new_team.max_members
      errors.add(:team_id, "team has reached maximum member limit of #{new_team.max_members}")
    end
  end

  def validate_direct_user_team_constraints
    if team_id.present? || team_role.present?
      errors.add(:base, "direct users cannot have team associations")
    end
  end

  # Validation method for system role changes
  def system_role_change_allowed
    # Allow system role changes during user creation
    return if new_record?

    # Get the current admin user from thread-local storage if available
    current_admin = Thread.current[:current_admin_user]

    # If we can't determine the current admin, allow the change
    # (This handles cases like console updates, seeds, etc.)
    return unless current_admin

    # Prevent admins from changing their own system role
    if current_admin.id == id
      errors.add(:system_role, "cannot be changed by yourself")
      return
    end

    # Validate role transition rules
    old_role = system_role_was
    new_role = system_role

    case old_role
    when "super_admin"
      unless %w[site_admin user].include?(new_role)
        errors.add(:system_role, "super_admin can only be changed to site_admin or user")
      end
    when "site_admin"
      unless %w[super_admin user].include?(new_role)
        errors.add(:system_role, "site_admin can only be changed to super_admin or user")
      end
    when "user"
      unless %w[site_admin super_admin].include?(new_role)
        errors.add(:system_role, "user can only be changed to site_admin or super_admin")
      end
    end
  end
end
