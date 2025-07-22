# Controller for managing user notifications using Noticed gem
# Provides functionality to view, mark as read, and delete notifications
# Supports HTML, Turbo Stream, and JSON responses for interactive UI
class NotificationsController < ApplicationController
  # Require authentication - notifications are personal to each user
  before_action :authenticate_user!
  # Load notification for individual actions
  before_action :set_notification, only: [ :mark_as_read, :destroy ]

  # Skip Pundit for bulk collection actions (they operate on current_user scope)
  skip_after_action :verify_authorized, only: [ :mark_all_as_read, :destroy_all ]
  # Skip policy scope for index - we manually scope to current_user
  skip_after_action :verify_policy_scoped, only: [ :index ]

  # GET /notifications
  # Display paginated list of user notifications
  # Automatically marks notifications as seen when viewed
  def index
    # Load user's notifications with eager loading for performance
    # No policy scope needed - already scoped to current_user
    @notifications = current_user.notifications
                                 .includes(:event) # Avoid N+1 queries
                                 .order(created_at: :desc) # Newest first

    # Paginate results (20 per page)
    @pagy, @notifications = pagy(@notifications, items: 20)

    # Mark notifications as seen when user views the page
    # This updates the notification bell/counter in the UI
    current_user.notifications.unseen.update_all(seen_at: Time.current)
  end

  # PATCH /notifications/:id/mark_as_read
  # Mark individual notification as read
  # Supports multiple response formats for interactive UI
  def mark_as_read
    # Ensure user can only mark their own notifications as read
    authorize @notification, :mark_as_read?
    # Update notification with read timestamp
    @notification.mark_as_read!

    respond_to do |format|
      # HTML: redirect back to previous page
      format.html { redirect_back(fallback_location: notifications_path) }
      # Turbo Stream: remove notification from list dynamically
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@notification) }
      # JSON API: return status and updated unread count
      format.json { render json: { status: "ok", unread_count: current_user.notifications.unread.count } }
    end
  end

  # PATCH /notifications/mark_all_as_read
  # Mark all user notifications as read in bulk
  # Efficient single query operation
  def mark_all_as_read
    # Bulk update all unread notifications with current timestamp
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      # HTML: redirect with success message
      format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
      # Turbo Stream: update UI dynamically
      format.turbo_stream
      # JSON API: return success status with zero unread count
      format.json { render json: { status: "ok", unread_count: 0 } }
    end
  end

  # DELETE /notifications/:id
  # Delete individual notification permanently
  def destroy
    # Ensure user can only delete their own notifications
    authorize @notification
    # Remove notification from database
    @notification.destroy

    respond_to do |format|
      # HTML: redirect back to previous page
      format.html { redirect_back(fallback_location: notifications_path) }
      # Turbo Stream: remove from UI dynamically
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@notification) }
      # JSON API: return success status
      format.json { head :no_content }
    end
  end

  # DELETE /notifications/destroy_all
  # Delete all user notifications permanently
  # Bulk operation for clearing notification history
  def destroy_all
    # Remove all notifications for current user
    current_user.notifications.destroy_all

    respond_to do |format|
      # HTML: redirect with success message
      format.html { redirect_to notifications_path, notice: "All notifications cleared." }
      # Turbo Stream: update UI to show empty state
      format.turbo_stream
      # JSON API: return success status
      format.json { head :no_content }
    end
  end

  private

  # Load notification scoped to current user
  # Ensures users can only access their own notifications
  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
