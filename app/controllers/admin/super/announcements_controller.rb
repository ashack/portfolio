# Super Admin Announcements Controller
#
# PURPOSE:
# Provides complete CRUD interface for system-wide announcements that super admins can create,
# manage, and publish to all users across the platform.
#
# ACCESS RESTRICTIONS:
# - Only super admins can create, edit, and delete announcements
# - Full control over announcement lifecycle and publishing
# - Can target announcements to specific user types or platform-wide
# - Inherits from Admin::Super::BaseController which enforces super_admin role
#
# BUSINESS RULES:
# - Super admins create announcements for platform communication
# - Announcements can be scheduled with start/end dates
# - Support different styles (info, warning, success, error)
# - Can be dismissible or persistent
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Announcements visible to all user types (direct, team, enterprise)
# - Site admins can view announcements for customer support context
# - Platform-wide communication for all ecosystems
module Admin
  module Super
    class AnnouncementsController < Admin::Super::BaseController
      before_action :set_announcement, only: [ :show, :edit, :update, :destroy ]

      # Display paginated list of all announcements for super admin management
      #
      # FEATURES:
      # - All announcements regardless of status or publication state
      # - Includes creator information for audit trail
      # - Recent announcements first for management relevance
      #
      # SECURITY:
      # - Uses Pundit policy_scope (though super admin sees all)
      # - Includes created_by association to prevent N+1 queries
      #
      # MANAGEMENT USE CASES:
      # - Review all platform announcements
      # - Monitor announcement publishing schedule
      # - Manage announcement lifecycle
      def index
        @pagy, @announcements = pagy(policy_scope(Announcement).includes(:created_by).order(created_at: :desc))
      end

      # Display individual announcement details for super admin review
      #
      # USE CASES:
      # - Review announcement before publishing
      # - Check announcement configuration and targeting
      # - Verify announcement content and styling
      def show
      end

      # Display new announcement creation form
      #
      # DEFAULTS:
      # - starts_at set to current time for immediate publishing
      # - Other fields use model defaults
      #
      # AUTHORIZATION:
      # - Verifies super admin can create announcements
      def new
        @announcement = Announcement.new(starts_at: Time.current)
        authorize @announcement
      end

      # Create new announcement with audit trail
      #
      # AUDIT TRAIL:
      # - Sets created_by to current super admin for accountability
      # - Tracks who created each announcement
      #
      # BUSINESS LOGIC:
      # - Validates announcement parameters
      # - Handles publishing schedule and targeting
      #
      # SUCCESS FLOW:
      # - Redirects to show page for immediate review
      # - Confirms successful creation to admin
      def create
        @announcement = Announcement.new(announcement_params)
        @announcement.created_by = current_user
        authorize @announcement

        if @announcement.save
          redirect_to admin_super_announcement_path(@announcement),
                      notice: "Announcement was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      # Display announcement editing form
      #
      # USE CASES:
      # - Modify announcement content before or after publishing
      # - Update announcement scheduling
      # - Change announcement styling or targeting
      def edit
      end

      # Update existing announcement with validation
      #
      # BUSINESS LOGIC:
      # - Allows modification of published announcements
      # - Updates take effect immediately if announcement is active
      #
      # SUCCESS FLOW:
      # - Redirects to show page for immediate review of changes
      # - Confirms successful update to admin
      def update
        if @announcement.update(announcement_params)
          redirect_to admin_super_announcement_path(@announcement),
                      notice: "Announcement was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      # Delete announcement permanently
      #
      # DESTRUCTIVE ACTION:
      # - Permanently removes announcement from system
      # - Use destroy! to raise exceptions on failure
      #
      # USE CASES:
      # - Remove outdated announcements
      # - Delete mistakenly created announcements
      # - Clean up old announcements for platform maintenance
      def destroy
        @announcement.destroy!
        redirect_to admin_super_announcements_path,
                    notice: "Announcement was successfully deleted."
      end

      private

      # Find and authorize announcement for admin actions
      #
      # SECURITY:
      # - Uses find() to raise 404 if announcement doesn't exist
      # - Authorizes each action through Pundit
      def set_announcement
        @announcement = Announcement.find(params[:id])
        authorize @announcement
      end

      # Strong parameters for announcement creation and updates
      #
      # PERMITTED FIELDS:
      # - title: Announcement headline
      # - message: Full announcement content
      # - style: Visual styling (info, warning, success, error)
      # - dismissible: Whether users can dismiss the announcement
      # - starts_at: When announcement becomes visible
      # - ends_at: When announcement expires (optional)
      # - published: Whether announcement is active
      #
      # SECURITY:
      # - Only allows safe announcement fields
      # - No user targeting parameters (platform-wide by default)
      def announcement_params
        params.require(:announcement).permit(
          :title,
          :message,
          :style,
          :dismissible,
          :starts_at,
          :ends_at,
          :published
        )
      end
    end
  end
end
