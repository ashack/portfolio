class Admin::Site::AnnouncementsController < Admin::Site::BaseController
  def index
    @announcements = policy_scope(Announcement).order(starts_at: :desc)
    @pagy, @announcements = pagy(@announcements, items: 20)
  end

  def show
    @announcement = Announcement.find(params[:id])
    authorize @announcement
  end
end
