# Announcement model for site-wide announcements
# Supports scheduled publishing, dismissible banners, and various styling options
class Announcement < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: "User"

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :message, presence: true
  validates :style, presence: true, inclusion: { in: %w[info success warning danger] }
  validates :starts_at, presence: true
  validate :ends_at_after_starts_at, if: :ends_at?

  # Scopes
  scope :published, -> { where(published: true) }
  scope :active, -> {
    published
      .where("starts_at <= ?", Time.current)
      .where("ends_at IS NULL OR ends_at >= ?", Time.current)
  }
  scope :current, -> { active.order(created_at: :desc).first }
  scope :upcoming, -> { published.where("starts_at > ?", Time.current).order(starts_at: :asc) }
  scope :expired, -> { published.where("ends_at < ?", Time.current).order(ends_at: :desc) }

  # Callbacks
  after_update :send_notifications, if: :just_published?

  # Instance methods
  def active?
    published? && starts_at <= Time.current && (ends_at.nil? || ends_at >= Time.current)
  end

  def upcoming?
    published? && starts_at > Time.current
  end

  def expired?
    published? && ends_at.present? && ends_at < Time.current
  end

  def style_classes
    base_classes = "px-4 py-3 rounded-lg border relative"

    case style
    when "info"
      "#{base_classes} bg-blue-50 border-blue-200 text-blue-800"
    when "success"
      "#{base_classes} bg-green-50 border-green-200 text-green-800"
    when "warning"
      "#{base_classes} bg-yellow-50 border-yellow-200 text-yellow-800"
    when "danger"
      "#{base_classes} bg-red-50 border-red-200 text-red-800"
    else
      "#{base_classes} bg-gray-50 border-gray-200 text-gray-800"
    end
  end

  def icon
    case style
    when "info"
      "information-circle"
    when "success"
      "check-circle"
    when "warning"
      "exclamation-triangle"
    when "danger"
      "x-circle"
    else
      "megaphone"
    end
  end

  private

  def ends_at_after_starts_at
    return unless ends_at.present? && starts_at.present?

    if ends_at <= starts_at
      errors.add(:ends_at, "must be after the start date")
    end
  end

  def just_published?
    saved_change_to_published? && published?
  end

  def send_notifications
    # Queue job to send notifications to all users
    NotifyUsersAboutAnnouncementJob.perform_later(self)
  end
end

