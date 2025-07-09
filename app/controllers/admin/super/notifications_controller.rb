class Admin::Super::NotificationsController < Admin::Super::BaseController
  def index
    @notifications = Noticed::Event.order(created_at: :desc)
    @pagy, @notifications = pagy(@notifications, items: 20)
  end

  def new
    @notification = NotificationForm.new
    @recipient_options = recipient_options
  end

  def create
    @notification = NotificationForm.new(notification_params)
    
    if @notification.valid?
      # Determine recipients based on selection
      recipients = case @notification.recipient_type
      when 'all_users'
        User.active
      when 'all_admins'
        User.where(system_role: ['super_admin', 'site_admin'])
      when 'all_team_admins'
        User.invited.where(team_role: 'admin')
      when 'specific_user'
        User.where(id: @notification.recipient_ids)
      when 'specific_team'
        Team.find(@notification.team_id).users
      else
        []
      end

      if recipients.any?
        # Create the notification
        case @notification.notification_type
        when 'system_announcement'
          SystemAnnouncementNotifier.with(
            title: @notification.title,
            message: @notification.message,
            priority: @notification.priority,
            announcement_type: @notification.announcement_type
          ).deliver(recipients)
        when 'admin_action'
          recipients.each do |recipient|
            AdminActionNotifier.with(
              action: @notification.action,
              admin: current_user,
              details: { note: @notification.message }
            ).deliver(recipient)
          end
        when 'custom'
          # For custom notifications, we'll use SystemAnnouncementNotifier
          SystemAnnouncementNotifier.with(
            title: @notification.title,
            message: @notification.message,
            priority: @notification.priority,
            announcement_type: 'general'
          ).deliver(recipients)
        end

        redirect_to admin_super_notifications_path, 
          notice: "Notification sent to #{recipients.count} recipient(s)"
      else
        flash.now[:alert] = "No recipients selected"
        @recipient_options = recipient_options
        render :new
      end
    else
      @recipient_options = recipient_options
      render :new
    end
  end

  def show
    @notification_event = Noticed::Event.find(params[:id])
    @notifications = @notification_event.notifications.includes(:recipient)
    @pagy, @notifications = pagy(@notifications, items: 20)
  end

  private

  def notification_params
    params.require(:notification_form).permit(
      :notification_type, :recipient_type, :title, :message, 
      :priority, :announcement_type, :action, :team_id,
      recipient_ids: []
    )
  end

  def recipient_options
    {
      users: User.active.order(:email).pluck(:email, :id),
      teams: Team.active.order(:name).pluck(:name, :id)
    }
  end
end

# Form object for notification creation
class NotificationForm
  include ActiveModel::Model

  attr_accessor :notification_type, :recipient_type, :recipient_ids, 
                :team_id, :title, :message, :priority, 
                :announcement_type, :action

  validates :notification_type, presence: true
  validates :recipient_type, presence: true
  validates :message, presence: true
  validates :title, presence: true, if: -> { notification_type == 'system_announcement' }
  validates :priority, inclusion: { in: %w[low medium high critical] }, allow_blank: true

  def initialize(attributes = {})
    super
    @priority ||= 'medium'
    @announcement_type ||= 'general'
  end
end