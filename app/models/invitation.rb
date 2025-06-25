# Invitation model handles the invitation system for both teams and enterprises
# Uses polymorphic associations to support multiple invitable types
#
# CRITICAL BUSINESS RULES:
# - Invitations can ONLY be sent to emails NOT in users table (CR-I1)
# - Invitations expire after 7 days (CR-I2)
# - Accepted invitations cannot be revoked (user already exists)
# - Email validation prevents duplicate accounts
class Invitation < ApplicationRecord
  # Legacy support - team association for backward compatibility
  belongs_to :team, optional: true

  # Polymorphic association for flexible invitation types
  # Can be associated with Team or EnterpriseGroup
  belongs_to :invitable, polymorphic: true, optional: true

  # User who sent the invitation (for audit trail)
  belongs_to :invited_by, class_name: "User"

  # Role the invited user will have
  # - member: Standard access
  # - admin: Full management access
  enum :role, { member: 0, admin: 1 }

  # Type of invitation for proper user creation
  # - team: Creates invited user with team association
  # - enterprise: Creates enterprise user with enterprise association
  enum :invitation_type, { team: "team", enterprise: "enterprise" }

  # ========================================================================
  # VALIDATIONS
  # ========================================================================

  # Email must be valid format
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Token must be unique for security
  validates :token, presence: true, uniqueness: true

  # Expiration is required for security
  validates :expires_at, presence: true

  # Must specify invitation type
  validates :invitation_type, presence: true

  # Conditional validations based on invitation type
  # Team invitations need team_id, enterprise need invitable
  validates :team_id, presence: true, if: :team_invitation?
  validates :invitable, presence: true, if: :enterprise_invitation?

  # CR-I1: Email cannot exist in users table
  # Core rule to prevent duplicate accounts
  validate :email_not_in_users_table

  # Prevent duplicate pending invitations for same email and team
  validate :no_duplicate_pending_invitations

  # CR-I2: Cannot accept expired invitations
  validate :not_expired, on: :accept

  # Ensure invitation type matches invitable type
  validate :invitation_type_matches_invitable

  # ========================================================================
  # CALLBACKS
  # ========================================================================

  # Normalize email for consistency
  before_validation :normalize_email

  # Generate secure random token for invitation URLs
  before_validation :generate_token, if: :new_record?

  # Set expiration to 7 days from creation
  before_validation :set_expiration, if: :new_record?

  # Set polymorphic association for legacy team invitations
  before_validation :set_invitable_from_team, if: :team_invitation?

  # ========================================================================
  # SCOPES
  # ========================================================================

  # Invitations that haven't been accepted yet
  scope :pending, -> { where(accepted_at: nil) }

  # Invitations that haven't expired
  scope :active, -> { where("expires_at > ?", Time.current) }

  # Filter by invitation type
  scope :for_teams, -> { where(invitation_type: "team") }
  scope :for_enterprise, -> { where(invitation_type: "enterprise") }

  # ========================================================================
  # PUBLIC INSTANCE METHODS
  # ========================================================================

  # Override to_param for SEO-friendly URLs
  # Uses token instead of ID for security
  def to_param
    token
  end

  # Checks if invitation has expired
  def expired?
    expires_at < Time.current
  end

  # Checks if invitation has been accepted
  def accepted?
    accepted_at.present?
  end

  # Checks if invitation is still pending
  def pending?
    !accepted?
  end

  # Accepts the invitation and creates a new user
  # This is the core method that:
  # 1. Validates invitation is valid (not expired, not accepted)
  # 2. Creates appropriate user type based on invitation
  # 3. Sets up proper associations
  # 4. Updates enterprise admin if needed
  #
  # Returns the created user or false if invalid
  def accept!(user_attributes = {})
    return false if expired? || accepted?

    User.transaction do
      # Mark invitation as accepted first to avoid validation conflicts
      update_column(:accepted_at, Time.current)

      user = if team_invitation?
        # Create invited user with team association
        User.create!(
          email: email,
          user_type: "invited",
          team: team,
          team_role: role,
          status: "active",
          accepting_invitation: true,
          **user_attributes
        )
      elsif enterprise_invitation?
        # Create enterprise user with enterprise association
        enterprise_group = invitable
        User.create!(
          email: email,
          user_type: "enterprise",
          enterprise_group: enterprise_group,
          enterprise_group_role: role,
          status: "active",
          accepting_invitation: true,
          **user_attributes
        )
      end

      # Special handling for enterprise admin invitations
      # Sets the user as the enterprise group admin only if there isn't one
      if enterprise_invitation? && admin? && invitable.admin.nil?
        invitable.update!(admin: user)
      end

      user
    end
  end

  # Helper to check if this is a team invitation
  def team_invitation?
    invitation_type == "team" || team.present?
  end

  # Helper to check if this is an enterprise invitation
  def enterprise_invitation?
    invitation_type == "enterprise"
  end

  private

  # ========================================================================
  # PRIVATE METHODS
  # ========================================================================

  # Sets invitable association for legacy team invitations
  # Ensures polymorphic association is set properly
  def set_invitable_from_team
    if team.present? && invitable.blank?
      self.invitable = team
    end
  end

  # Normalizes email to lowercase and strips whitespace
  def normalize_email
    self.email = email&.downcase&.strip
  end

  # CR-I1: Validates email doesn't exist in users table
  # Core business rule to prevent duplicate accounts
  def email_not_in_users_table
    return unless email.present?

    if User.exists?(email: email.downcase)
      errors.add(:email, "already has an account")
    end
  end

  # CR-I2: Validates invitation hasn't expired
  # Security measure to prevent old invitations from being used
  def not_expired
    if expired?
      errors.add(:base, "Invitation has expired")
    end
  end

  # Generates cryptographically secure random token
  # Used in invitation URLs for security
  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  # Sets expiration to 7 days from now
  # Security best practice to limit invitation lifetime
  def set_expiration
    self.expires_at = 7.days.from_now
  end

  # Validates that invitation type matches the invitable type
  def invitation_type_matches_invitable
    return unless invitable.present?

    case invitation_type
    when "team"
      unless invitable.is_a?(Team)
        errors.add(:invitation_type, "does not match invitable type")
      end
    when "enterprise"
      unless invitable.is_a?(EnterpriseGroup)
        errors.add(:invitation_type, "does not match invitable type")
      end
    end
  end

  # Prevent duplicate pending invitations for same email and team
  def no_duplicate_pending_invitations
    return unless email.present? && team_id.present?

    existing = Invitation.pending.where(email: email.downcase, team_id: team_id)
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:email, "conflicts with pending team invitation for #{team.name}")
    end
  end
end
