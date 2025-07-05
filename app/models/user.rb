# User model represents all users in the system with three distinct types:
# 1. Direct users - Register independently, can create teams, have personal billing
# 2. Invited users - Join via team invitation only, no personal billing
# 3. Enterprise users - Join via enterprise invitation only, separate billing
#
# CRITICAL BUSINESS RULES:
# - User type CANNOT be changed after creation (CR-U1)
# - Each user type has exclusive associations (CR-U2)
# - Direct users can only be associated with teams they own (CR-U3)
class User < ApplicationRecord
  # Pay gem integration for individual user billing (direct users only)
  pay_customer

  # Devise modules for authentication and security
  # - database_authenticatable: Username/password authentication
  # - registerable: Users can sign up
  # - recoverable: Password reset functionality
  # - rememberable: Remember me cookie support
  # - validatable: Email/password validation
  # - confirmable: Email confirmation required
  # - trackable: Track sign in count, timestamps, IP
  # - lockable: Lock account after failed attempts
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :trackable, :lockable

  # Association to team (only for invited users)
  belongs_to :team, optional: true

  # Association to plan (for direct users with individual billing)
  belongs_to :plan, optional: true

  # Association to enterprise group (only for enterprise users)
  belongs_to :enterprise_group, optional: true

  # Active Storage association for avatar
  has_one_attached :avatar

  # Teams created by this user (super admins only)
  has_many :created_teams, class_name: "Team", foreign_key: "created_by_id"

  # Teams where this user is the designated admin
  has_many :administered_teams, class_name: "Team", foreign_key: "admin_id"

  # Enterprise groups created by this user (super admins only)
  has_many :created_enterprise_groups, class_name: "EnterpriseGroup", foreign_key: "created_by_id"

  # Enterprise groups where this user is the admin
  has_many :administered_enterprise_groups, class_name: "EnterpriseGroup", foreign_key: "admin_id"

  # Invitations sent by this user
  has_many :sent_invitations, class_name: "Invitation", foreign_key: "invited_by_id"

  # Analytics tracking via Ahoy
  has_many :ahoy_visits, class_name: "Ahoy::Visit"

  # Audit logs for security and compliance
  has_many :audit_logs, foreign_key: "user_id", dependent: :destroy
  has_many :target_audit_logs, class_name: "AuditLog", foreign_key: "target_user_id", dependent: :destroy

  # Email change requests (require admin approval)
  has_many :email_change_requests, dependent: :destroy
  has_many :approved_email_changes, class_name: "EmailChangeRequest", foreign_key: "approved_by_id"

  # User preferences for UI settings
  # Currently stores pagination preferences per controller
  # Each user can have different items per page for different sections
  has_one :user_preference, dependent: :destroy

  # System-wide administrative role
  # - user: Standard user, no admin access
  # - site_admin: Customer support, read-only billing
  # - super_admin: Full system access, can create teams/enterprises
  enum :system_role, { user: 0, site_admin: 1, super_admin: 2 }

  # User account type (IMMUTABLE after creation)
  # - direct: Self-registered, can create teams
  # - invited: Joined via team invitation
  # - enterprise: Joined via enterprise invitation
  enum :user_type, { direct: 0, invited: 1, enterprise: 2 }

  # Account status for access control
  # - active: Normal access
  # - inactive: Cannot sign in (deactivated)
  # - locked: Cannot sign in (security flag)
  enum :status, { active: 0, inactive: 1, locked: 2 }

  # Role within a team (invited users only)
  # - member: Basic team access
  # - admin: Can manage team members and settings
  enum :team_role, { member: 0, admin: 1 }

  # Role within enterprise group (enterprise users only)
  # Prefixed to avoid conflicts with team_role
  enum :enterprise_group_role, { member: 0, admin: 1 }, prefix: true

  # Virtual attribute for team name during registration
  # Used when direct users select a team plan and need to provide team name
  attr_accessor :team_name

  # Virtual attribute to skip invitation conflict check when accepting an invitation
  # Set to true in registration controller when processing invitation acceptance
  attr_accessor :accepting_invitation

  # ========================================================================
  # VALIDATIONS
  # ========================================================================

  # Basic presence validations
  validates :user_type, presence: true
  validates :status, presence: true

  # Name field validations with user-friendly error messages
  # Allows common name characters including spaces, hyphens, apostrophes, periods
  validates :first_name, length: { maximum: 50, message: "must be 50 characters or less" },
                        format: { with: /\A[a-zA-Z\s\-'\.]*\z/, message: "can only contain letters, spaces, hyphens, apostrophes, and periods" },
                        allow_blank: true

  validates :last_name, length: { maximum: 50, message: "must be 50 characters or less" },
                       format: { with: /\A[a-zA-Z\s\-'\.]*\z/, message: "can only contain letters, spaces, hyphens, apostrophes, and periods" },
                       allow_blank: true

  # Email validation with custom messages
  # Enforces uniqueness case-insensitively to prevent duplicate accounts
  validates :email, presence: { message: "is required" },
                   uniqueness: { case_sensitive: false, message: "is already taken" },
                   format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  # CR-A1: Strong password requirements
  # Enforces: 8+ chars, uppercase, lowercase, number, special character
  validate :password_complexity, if: :password_required?

  # CR-I1: Prevent email conflicts with pending invitations
  # Ensures new users can't register with email that has pending invitation
  validate :email_not_in_pending_invitations, if: :email_changed?

  # CR-U1: Core business rule - user type immutability
  # CRITICAL: Changing user type would break billing and permissions
  validate :user_type_cannot_be_changed, if: :user_type_changed?

  # CR-U3: Direct users can only have team associations if they own the team
  # Prevents direct users from bypassing invitation system
  validate :direct_user_team_ownership

  # Invited user validations - must have team association
  validates :team_id, presence: { message: "is required for team members" }, if: :invited?
  validates :team_role, presence: { message: "is required for team members" }, if: :invited?

  # Enterprise user validations - must have enterprise association
  validates :enterprise_group_id, presence: { message: "is required for enterprise users" }, if: :enterprise?
  validates :enterprise_group_role, presence: { message: "is required for enterprise users" }, if: :enterprise?

  # CR-U2: Ensure user type associations are mutually exclusive
  # Direct users can't have enterprise associations, etc.
  validate :user_type_associations_valid

  # Additional team constraint validations
  # Ensures team integrity (member limits, admin requirements, etc.)
  validate :team_constraints_remain_intact, if: :team_association_changed?

  # CR-A3: Prevent admins from changing their own system role
  # Security measure to prevent privilege escalation
  validate :system_role_change_allowed, if: :system_role_changed?

  # ========================================================================
  # ENHANCED PROFILE FIELD VALIDATIONS
  # ========================================================================

  # Profile visibility settings
  enum :profile_visibility, { public_profile: 0, team_only: 1, private_profile: 2 }, prefix: true

  # Phone number validation
  validates :phone_number, format: { with: /\A[+]?[0-9\s\-().]+\z/, message: "must be a valid phone number" },
                          length: { maximum: 20 },
                          allow_blank: true

  # Bio validation
  validates :bio, length: { maximum: 500, message: "must be 500 characters or less" },
                 allow_blank: true

  # URL validations
  validates :linkedin_url, :twitter_url, :github_url, :website_url,
            format: { with: URI.regexp([ "http", "https" ]), message: "must be a valid URL" },
            allow_blank: true

  # Timezone validation
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) },
                      allow_blank: true

  # Locale validation
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) },
                    allow_blank: true

  # Avatar validation
  validate :acceptable_avatar

  # ========================================================================
  # CALLBACKS
  # ========================================================================

  # Normalize email to lowercase for consistency
  # Prevents duplicate accounts with different case
  before_validation :normalize_email

  # SECURITY: Prevent unauthorized email changes
  # Email changes must go through the EmailChangeRequest system
  before_save :prevent_unauthorized_email_change, if: :email_changed?

  # Include ValidationHelpers concern for additional validation methods
  include ValidationHelpers

  # ========================================================================
  # SCOPES
  # ========================================================================

  # Filter for active users only
  scope :active, -> { where(status: "active") }

  # Filter for direct (self-registered) users
  scope :direct_users, -> { where(user_type: "direct") }

  # Filter for team members (invited users)
  scope :team_members, -> { where(user_type: "invited") }

  # Eager load associations to prevent N+1 queries
  scope :with_associations, -> { includes(:team, :plan, :enterprise_group) }

  # Eager load team details for team member listings
  scope :with_team_details, -> { includes(team: [ :admin, :users ]) }

  # ========================================================================
  # PUBLIC INSTANCE METHODS
  # ========================================================================

  # Returns the user's full name, handling nil values gracefully
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # Returns the user's initials for avatar display
  def initials
    name_parts = []
    name_parts << first_name[0] if first_name.present?
    name_parts << last_name[0] if last_name.present?

    # Fall back to email if no name is set
    if name_parts.empty? && email.present?
      name_parts << email[0].upcase
    end

    name_parts.join.upcase
  end

  # Determines if user can sign in based on status
  # Used by authentication system
  def can_sign_in?
    active?
  end

  # Checks if user is a team admin
  # Returns true for:
  # - Invited users with admin role
  # - Direct users who own a team
  def team_admin?
    (invited? && team_role == "admin") || (direct? && owns_team? && team.present?)
  end

  # Checks if user is a regular team member (not admin)
  def team_member?
    invited? && team_role == "member"
  end

  # Checks if user is an enterprise admin
  def enterprise_admin?
    enterprise? && enterprise_group_role == "admin"
  end

  # Checks if user is an enterprise member (not admin)
  def enterprise_member?
    enterprise? && enterprise_group_role == "member"
  end

  # Determines if user can create a new team
  # Only direct users who don't already own a team can create one
  def can_create_team?
    direct? && !owns_team?
  end

  # ========================================================================
  # PROFILE METHODS
  # ========================================================================

  # Calculates profile completion percentage
  def calculate_profile_completion
    total_fields = 10
    completed_fields = 0

    # Basic fields
    completed_fields += 1 if first_name.present?
    completed_fields += 1 if last_name.present?
    completed_fields += 1 if bio.present?
    completed_fields += 1 if phone_number.present?
    completed_fields += 1 if avatar.attached? || avatar_url.present?

    # Social links (count as one if any present)
    if linkedin_url.present? || twitter_url.present? || github_url.present? || website_url.present?
      completed_fields += 1
    end

    # Preferences
    completed_fields += 1 if timezone != "UTC"
    completed_fields += 1 if locale != "en"
    completed_fields += 1 if notification_preferences.present? && notification_preferences.any?
    completed_fields += 1 if two_factor_enabled?

    percentage = (completed_fields.to_f / total_fields * 100).round

    # Update the database
    update_columns(
      profile_completion_percentage: percentage,
      profile_completed_at: percentage == 100 ? Time.current : nil
    )

    percentage
  end

  # Returns true if profile is complete
  def profile_complete?
    profile_completion_percentage == 100
  end

  # Returns a hash of missing profile fields
  def missing_profile_fields
    missing = []

    missing << "First name" unless first_name.present?
    missing << "Last name" unless last_name.present?
    missing << "Bio" unless bio.present?
    missing << "Phone number" unless phone_number.present?
    missing << "Profile picture" unless avatar.attached? || avatar_url.present?
    missing << "Social links" unless has_social_links?
    missing << "Timezone" if timezone == "UTC"
    missing << "Language preference" if locale == "en"
    missing << "Notification preferences" unless notification_preferences.present? && notification_preferences.any?
    missing << "Two-factor authentication" unless two_factor_enabled?

    missing
  end

  # Check if user has any social links
  def has_social_links?
    linkedin_url.present? || twitter_url.present? || github_url.present? || website_url.present?
  end

  # Returns formatted phone number
  def formatted_phone_number
    return nil unless phone_number.present?
    phone_number # Could add formatting logic here
  end

  # Returns user's timezone as ActiveSupport::TimeZone
  def time_zone
    ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone["UTC"]
  end

  # Returns avatar URL - either from Active Storage or avatar_url field
  def display_avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    else
      avatar_url
    end
  end

  # ========================================================================
  # DEVISE OVERRIDES
  # ========================================================================

  # Override Devise method to check our custom status field
  # Prevents inactive/locked users from signing in
  def active_for_authentication?
    # First check Devise's built-in checks (including lockable)
    return false unless super
    # Then check our custom status
    can_sign_in?
  end

  # Override Devise method to provide custom inactive messages
  # Maps our status values to Devise message keys
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

  # ========================================================================
  # HELPER METHODS
  # ========================================================================

  # Checks if account needs unlocking (for admin UI)
  def needs_unlock?
    access_locked? && (failed_attempts > 0 || locked_at.present?)
  end

  # Returns human-readable lock status for admin display
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

  # ========================================================================
  # PRIVATE VALIDATION METHODS
  # ========================================================================

  # Normalizes email to lowercase and strips whitespace
  # Called before validation to ensure consistency
  def normalize_email
    self.email = email&.downcase&.strip
  end

  # SECURITY: Prevent unauthorized email changes
  # Email changes must go through the EmailChangeRequest system with admin approval
  def prevent_unauthorized_email_change
    # Skip validation for new records (registration)
    return if new_record?

    # Skip if the change is being made by the EmailChangeRequest system
    # This is identified by checking if the change is happening within a transaction
    # that includes an EmailChangeRequest approval
    return if Thread.current[:email_change_authorized]

    # Allow super admins to change their own emails directly (for emergency situations)
    return if super_admin?

    # Also check Thread.current for admin actions
    return if Thread.current[:current_admin]&.super_admin?

    # If we get here, it's an unauthorized email change attempt
    errors.add(:email, "cannot be changed directly. Please use the email change request system.")

    # Log the attempt for security auditing
    Rails.logger.warn "[SECURITY] Unauthorized email change attempt for user #{id} from #{email_was} to #{email}"

    # Create audit log for security tracking
    AuditLogService.log_security_event(
      admin_user: self, # User attempting the change
      target_user: self, # Same user since it's self-modification
      event_type: "email_change_attempt_blocked_model",
      details: {
        attempted_email: email,
        current_email: email_was,
        model: "User",
        blocked_reason: "Model-level protection triggered"
      },
      request: nil # No request context in model
    )

    # Revert the email change
    self.email = email_was

    # Throw abort to prevent the save
    throw(:abort)
  end

  # CR-A1: Enforces strong password requirements
  # Requirements:
  # - Minimum 8 characters
  # - At least one uppercase letter (A-Z)
  # - At least one lowercase letter (a-z)
  # - At least one number (0-9)
  # - At least one special character
  def password_complexity
    return if password.blank?

    if password.length < 8
      errors.add :password, "must be at least 8 characters long"
    end

    unless password.match?(/[A-Z]/)
      errors.add :password, "must include at least one uppercase letter"
    end

    unless password.match?(/[a-z]/)
      errors.add :password, "must include at least one lowercase letter"
    end

    unless password.match?(/[0-9]/)
      errors.add :password, "must include at least one number"
    end

    unless password.match?(/[^A-Za-z0-9]/)
      errors.add :password, "must include at least one special character"
    end
  end

  # CR-I1: Prevents email conflicts with pending invitations
  # Users cannot register with an email that has a pending invitation
  # Exception: When accepting_invitation is true (set during invitation acceptance)
  def email_not_in_pending_invitations
    return unless email.present?

    # Skip this validation when accepting an invitation
    return if accepting_invitation

    # Check if the new email conflicts with any pending invitations
    pending_invitation = Invitation.pending.active.find_by(email: email.downcase)

    if pending_invitation
      errors.add(:email, "conflicts with pending team invitation for #{pending_invitation.team.name}")
    end
  end

  # CR-U1: Core business rule - user type immutability
  # CRITICAL: User type determines billing model, permissions, and associations
  # Changing it would corrupt the system's data integrity
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
    if team_id.present? && !owns_team?
      errors.add(:base, "direct users can only be associated with teams they own")
    end
  end

  def direct_user_team_ownership
    if direct? && team_id.present? && !owns_team?
      errors.add(:team_id, "direct users can only be associated with teams they own")
    end
  end

  def user_type_associations_valid
    case user_type
    when "direct"
      if enterprise_group_id.present? || enterprise_group_role.present?
        errors.add(:base, "direct users cannot have enterprise group associations")
      end
    when "invited"
      if enterprise_group_id.present? || enterprise_group_role.present?
        errors.add(:base, "team members cannot have enterprise group associations")
      end
      if owns_team?
        errors.add(:owns_team, "team members cannot own teams")
      end
    when "enterprise"
      if team_id.present? || team_role.present?
        errors.add(:base, "enterprise users cannot have team associations")
      end
      if owns_team?
        errors.add(:owns_team, "enterprise users cannot own teams")
      end
    end
  end

  # Validation method for system role changes
  def system_role_change_allowed
    # Allow system role changes during user creation
    return if new_record?

    # Get the current user ID from validation context
    context = validation_context_from_thread
    current_user_id = context[:current_user_id]

    # Use ValidationHelpers method to prevent self-promotion
    if current_user_id
      validate_no_self_promotion(current_user_id, :system_role)
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

  # Validates acceptable avatar file
  def acceptable_avatar
    return unless avatar.attached?

    # Check file size (max 5MB)
    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "is too large (maximum is 5MB)")
    end

    # Check file type
    acceptable_types = [ "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp" ]
    unless acceptable_types.include?(avatar.blob.content_type)
      errors.add(:avatar, "must be a JPEG, PNG, GIF, or WebP image")
    end
  end

  # ========================================================================
  # SUBSCRIPTION METHODS
  # ========================================================================

  # Override Pay gem's subscribed? method to always return true for admins
  def subscribed?
    # Super admins and site admins always have access
    return true if super_admin? || site_admin?

    # For regular users, use Pay gem's subscription check
    return false unless respond_to?(:payment_processor) && payment_processor.present?

    # Check if they have an active subscription
    payment_processor.subscriptions.active.any?
  end

  # Check if user has an active subscription (alias for clarity)
  def has_active_subscription?
    subscribed?
  end

  # Check if user requires a subscription
  def subscription_required?
    # Admins don't need subscriptions
    return false if super_admin? || site_admin?

    # Only direct users need subscriptions
    # Invited team members use their team's subscription
    # Enterprise users use their enterprise group's subscription
    direct?
  end

  # Get the current subscription (if any)
  def current_subscription
    return nil unless respond_to?(:payment_processor) && payment_processor.present?
    payment_processor.subscriptions.active.first
  end

  # Check if user can access premium features
  def can_access_premium_features?
    # Admins always have access
    return true if super_admin? || site_admin?

    # Check based on user type
    case user_type
    when "direct"
      # Direct users need their own subscription
      subscribed?
    when "invited"
      # Team members use their team's subscription
      team&.subscribed? || false
    when "enterprise"
      # Enterprise users use their enterprise group's subscription
      enterprise_group&.subscribed? || false
    else
      false
    end
  end
end
