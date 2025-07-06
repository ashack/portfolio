class EnterpriseGroup < ApplicationRecord
  include Cacheable
  pay_customer # For enterprise billing

  belongs_to :admin, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :plan
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, as: :invitable, dependent: :destroy
  has_many :notification_categories, dependent: :destroy

  enum :status, { active: 0, suspended: 1, cancelled: 2 }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :created_by_id, presence: true
  validates :plan_id, presence: true
  validate :plan_must_be_enterprise

  # Admin is optional during creation (will be set when invitation is accepted)
  validates :admin_id, presence: true, on: :update, if: :admin_required?

  before_validation :generate_slug, if: :name_changed?

  scope :active, -> { where(status: "active") }

  # Cache-friendly lookup by slug
  def self.find_by_slug!(slug)
    Rails.cache.fetch([ "enterprise-by-slug", slug ], expires_in: 1.hour) do
      find_by!(slug: slug)
    end
  end

  # Clear cache when enterprise group is updated
  after_commit :clear_caches

  def clear_caches
    Rails.cache.delete([ "enterprise-slug", id, updated_at ])
    Rails.cache.delete([ "enterprise-by-slug", slug ])
    Rails.cache.delete([ "enterprise-by-slug", slug_previously_was ]) if saved_change_to_slug?
  end

  def to_param
    # Cache the slug to avoid database lookups on every URL generation
    Rails.cache.fetch([ "enterprise-slug", id, updated_at ]) { slug }
  end

  def member_count
    users.count
  end

  def can_add_members?
    member_count < max_members
  end

  def pending_admin_invitation
    invitations.pending.admin.first
  end

  def has_pending_admin_invitation?
    pending_admin_invitation.present?
  end

  private

  def admin_required?
    !has_pending_admin_invitation?
  end

  def generate_slug
    return unless name.present?

    base_slug = name.downcase.gsub(/[^a-z0-9\s\-]/, "").gsub(/\s+/, "-").gsub(/^-+|-+$/, "")
    counter = 0
    potential_slug = base_slug

    while EnterpriseGroup.exists?(slug: potential_slug)
      counter += 1
      potential_slug = "#{base_slug}-#{counter}"
    end

    self.slug = potential_slug
  end

  def plan_must_be_enterprise
    return unless plan

    unless plan.plan_segment == "enterprise"
      errors.add(:plan, "must be an enterprise plan")
    end
  end
end
