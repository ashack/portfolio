class Admin::Site::NotificationsController < Admin::Site::BaseController
  def index
    @notifications = policy_scope(Noticed::Event).order(created_at: :desc)
    @pagy, @notifications = pagy(@notifications, items: 20)
  end

  def show
    @notification_event = Noticed::Event.find(params[:id])
    authorize @notification_event, policy_class: Noticed::EventPolicy
    @notifications = @notification_event.notifications.includes(:recipient)
    @pagy, @notifications = pagy(@notifications, items: 20)
  end
end
