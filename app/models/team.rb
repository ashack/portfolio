# Team model represents organizational units within the SaaS application
# Teams have their own:
# - Unique URL (via slug)
# - Billing subscription (separate from individual users)
# - Member management
# - Settings and configuration
#
# CRITICAL BUSINESS RULES:
# - Only Super Admins can create teams (CR-T1)
# - Teams cannot exceed their plan's member limit (CR-T2)
# - Every team must have at least one admin (CR-T3)
# - Teams cannot be deleted if they have users (data integrity)
class Team < ApplicationRecord
  # Pay gem integration for team-based billing
  # Handles Stripe subscriptions at the team level
  pay_customer

  # The designated admin user for this team
  # Can be changed but team must always have one
  belongs_to :admin, class_name: "User"

  # The super admin who created this team
  # Immutable - tracks who created the team for audit purposes
  belongs_to :created_by, class_name: "User"

  # Team members - uses restrict_with_error to prevent deletion
  # Teams with users cannot be deleted (must remove users first)
  has_many :users, dependent: :restrict_with_error

  # Team invitations - automatically cleaned up when team is deleted
  has_many :invitations, dependent: :destroy
  
  # Notification categories specific to this team
  has_many :notification_categories, dependent: :destroy

  # Subscription plan level
  # - starter: Basic features, 5 members max
  # - pro: Advanced features, 15 members max
  # - enterprise: Full features, 100 members max
  enum :plan, { starter: 0, pro: 1, enterprise: 2 }

  # Team account status
  # - active: Normal operation
  # - suspended: Temporarily disabled (e.g., payment issue)
  # - cancelled: Permanently closed
  enum :status, { active: 0, suspended: 1, cancelled: 2 }

  # Name validation - user-friendly team identifier
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }

  # Slug validation - URL-safe unique identifier
  # Used in URLs: /teams/team-slug/
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  # Ensure team always has an admin
  validates :admin_id, presence: true

  # Track who created the team
  validates :created_by_id, presence: true

  # Auto-generate URL-safe slug from team name
  before_validation :generate_slug, if: :name_changed?

  # ========================================================================
  # SCOPES
  # ========================================================================

  # Filter for active teams only
  scope :active, -> { where(status: "active") }

  # Eager load associations to prevent N+1 queries
  scope :with_associations, -> { includes(:admin, :created_by, :users) }

  # Include user count for efficient member limit checks
  scope :with_counts, -> { left_joins(:users).group(:id).select("teams.*, COUNT(users.id) as users_count") }

  # ========================================================================
  # CLASS METHODS
  # ========================================================================

  # Cache-friendly lookup by slug
  # Used by controllers to find teams by URL slug with caching
  def self.find_by_slug!(slug)
    Rails.cache.fetch([ "team-by-slug", slug ], expires_in: 1.hour) do
      find_by!(slug: slug)
    end
  end

  # ========================================================================
  # CALLBACKS
  # ========================================================================

  # Clear relevant caches when team is updated
  # Ensures slug changes are reflected immediately
  after_commit :clear_caches

  # ========================================================================
  # PUBLIC INSTANCE METHODS
  # ========================================================================

  # Override to_param for SEO-friendly URLs
  # Returns cached slug to avoid DB lookups on every URL generation
  def to_param
    Rails.cache.fetch([ "team-slug", id, updated_at ]) { slug }
  end

  # Returns current number of team members
  def member_count
    users.count
  end

  # CR-T2: Checks if team can add more members based on plan limit
  def can_add_members?
    member_count < max_members
  end

  # Returns array of features available for the team's plan
  # Used for feature gating in controllers and views
  def plan_features
    case plan
    when "starter"
      [ "team_dashboard", "collaboration", "email_support" ]
    when "pro"
      [ "team_dashboard", "collaboration", "advanced_team_features", "priority_support" ]
    when "enterprise"
      [ "team_dashboard", "collaboration", "advanced_team_features", "enterprise_features", "phone_support" ]
    end
  end

  private

  # ========================================================================
  # PRIVATE METHODS
  # ========================================================================

  # Clears all caches related to this team
  # Called after commits to ensure cache consistency
  def clear_caches
    Rails.cache.delete([ "team-slug", id, updated_at ])
    Rails.cache.delete([ "team-by-slug", slug ])
    # Clear old slug cache if slug changed
    Rails.cache.delete([ "team-by-slug", slug_previously_was ]) if saved_change_to_slug?
  end

  # Generates a URL-safe slug from the team name
  # Ensures uniqueness by appending numbers if needed
  # Examples:
  #   "My Team" -> "my-team"
  #   "Team @#$%" -> "team"
  #   "Duplicate" -> "duplicate-1" (if "duplicate" exists)
  def generate_slug
    return unless name.present?

    # Create base slug: lowercase, alphanumeric with hyphens
    base_slug = name.downcase.gsub(/[^a-z0-9\s\-]/, "").gsub(/\s+/, "-").gsub(/^-+|-+$/, "")
    counter = 0
    potential_slug = base_slug

    # Ensure uniqueness by appending counter if needed
    while Team.exists?(slug: potential_slug)
      counter += 1
      potential_slug = "#{base_slug}-#{counter}"
    end

    self.slug = potential_slug
  end
end
