module Admin
  module Super
    class AnnouncementsController < Admin::Super::BaseController
      before_action :set_announcement, only: [ :show, :edit, :update, :destroy ]

      def index
        @pagy, @announcements = pagy(policy_scope(Announcement).includes(:created_by).order(created_at: :desc))
      end

      def show
      end

      def new
        @announcement = Announcement.new(starts_at: Time.current)
        authorize @announcement
      end

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

      def edit
      end

      def update
        if @announcement.update(announcement_params)
          redirect_to admin_super_announcement_path(@announcement),
                      notice: "Announcement was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @announcement.destroy!
        redirect_to admin_super_announcements_path,
                    notice: "Announcement was successfully deleted."
      end

      private

      def set_announcement
        @announcement = Announcement.find(params[:id])
        authorize @announcement
      end

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
