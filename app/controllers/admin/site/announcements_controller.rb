# Site Admin Announcements Controller
#
# PURPOSE:
# Provides site admin interface for viewing and managing system-wide announcements.
# Site admins have read-only access to announcements created by super admins.
#
# ACCESS RESTRICTIONS:
# - Site admins can only VIEW announcements (no create/edit/delete)
# - Inherits from Admin::Site::BaseController which enforces site_admin role
# - Uses Pundit policies for authorization on individual announcements
#
# BUSINESS RULES:
# - Site admins provide customer support and need to see active announcements
# - Only super admins can create/modify announcements
# - All announcements are system-wide and visible to all user types
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Announcements can target different user types (direct, team, enterprise)
# - Site admins need visibility for customer support purposes
# - No billing or creation capabilities (read-only support role)
class Admin::Site::AnnouncementsController < Admin::Site::BaseController
  # Display paginated list of all announcements for site admin review
  #
  # SECURITY: Uses Pundit policy_scope to ensure site admin can only see appropriate announcements
  # PAGINATION: Shows 20 items per page, ordered by start date (newest first)
  # USE CASE: Site admins need to see active announcements when providing customer support
  def index
    @announcements = policy_scope(Announcement).order(starts_at: :desc)
    @pagy, @announcements = pagy(@announcements, items: 20)
  end

  # Display individual announcement details for site admin review
  #
  # SECURITY: Uses Pundit authorization to verify site admin can view this announcement
  # USE CASE: Site admins need detailed view when answering customer questions about announcements
  # AUDIT: No audit logging needed as this is read-only access
  def show
    @announcement = Announcement.find(params[:id])
    authorize @announcement
  end
end
