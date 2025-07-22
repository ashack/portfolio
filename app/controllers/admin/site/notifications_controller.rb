# Site Admin Notifications Controller
#
# PURPOSE:
# Provides site admin interface for viewing system notifications and events.
# Site admins can monitor notification delivery for customer support purposes.
#
# ACCESS RESTRICTIONS:
# - Site admins have READ-ONLY access to notifications
# - Cannot create, send, or modify notifications (only super admins can)
# - Can view notification events and delivery status for support
# - Inherits from Admin::Site::BaseController which enforces site_admin role
#
# BUSINESS RULES:
# - Site admins need visibility into notification delivery for support
# - Only super admins can create and send notifications
# - Uses Noticed gem for notification system management
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Notifications can be sent to all user types (direct, team, enterprise)
# - Site admins need visibility for troubleshooting delivery issues
# - Support customers who report missing notifications
class Admin::Site::NotificationsController < Admin::Site::BaseController
  # Display paginated list of notification events for site admin monitoring
  #
  # WHAT IT SHOWS:
  # - All notification events in the system
  # - Recent notifications first for support relevance
  # - Paginated view for performance
  #
  # SECURITY:
  # - Uses Pundit policy_scope to ensure site admin sees appropriate notifications
  # - No sensitive notification content exposed inappropriately
  #
  # SUPPORT USE CASES:
  # - Customer reports not receiving notifications
  # - Monitor system notification health
  # - Troubleshoot delivery issues
  def index
    @notifications = policy_scope(Noticed::Event).order(created_at: :desc)
    @pagy, @notifications = pagy(@notifications, items: 20)
  end

  # Display detailed notification event with all recipients for support analysis
  #
  # WHAT IT SHOWS:
  # - Specific notification event details
  # - All individual notifications sent from this event
  # - Delivery status and recipient information
  #
  # SECURITY:
  # - Uses Pundit authorization with custom policy class for Noticed events
  # - Includes recipient information for support context
  #
  # SUPPORT USE CASES:
  # - Verify if specific user received a notification
  # - Troubleshoot why notification wasn't delivered
  # - Understand notification reach and effectiveness
  #
  # PERFORMANCE:
  # - Includes recipient data to avoid N+1 queries
  # - Paginated recipient list for large notification events
  def show
    @notification_event = Noticed::Event.find(params[:id])
    authorize @notification_event, policy_class: Noticed::EventPolicy
    @notifications = @notification_event.notifications.includes(:recipient)
    @pagy, @notifications = pagy(@notifications, items: 20)
  end
end
