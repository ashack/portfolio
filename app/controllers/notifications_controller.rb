class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :mark_as_read, :destroy ]
  
  # Skip Pundit for collection actions
  skip_after_action :verify_authorized, only: [ :mark_all_as_read, :destroy_all ]
  skip_after_action :verify_policy_scoped, only: [ :index ]

  def index
    # Notifications are already scoped to current_user, no need for policy_scope
    @notifications = current_user.notifications
                                 .includes(:event)
                                 .order(created_at: :desc)

    @pagy, @notifications = pagy(@notifications, items: 20)

    # Mark notifications as seen when viewing the page
    current_user.notifications.unseen.update_all(seen_at: Time.current)
  end

  def mark_as_read
    authorize @notification, :mark_as_read?
    @notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@notification) }
      format.json { render json: { status: "ok", unread_count: current_user.notifications.unread.count } }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
      format.turbo_stream
      format.json { render json: { status: "ok", unread_count: 0 } }
    end
  end

  def destroy
    authorize @notification
    @notification.destroy

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@notification) }
      format.json { head :no_content }
    end
  end

  def destroy_all
    current_user.notifications.destroy_all

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications cleared." }
      format.turbo_stream
      format.json { head :no_content }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
