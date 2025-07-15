class Admin::Super::NotificationCategoriesController < Admin::Super::BaseController
  before_action :set_notification_category, only: [ :edit, :update, :destroy ]

  def index
    # Super admins can see all notification categories
    @notification_categories = NotificationCategory.includes(:created_by, :team, :enterprise_group)
                                                   .order(scope: :asc, created_at: :desc)
    @pagy, @notification_categories = pagy(@notification_categories, items: 20)
  end

  def new
    @notification_category = NotificationCategory.new(scope: "system")
  end

  def create
    @notification_category = NotificationCategory.new(notification_category_params)
    @notification_category.created_by = current_user

    # Auto-generate key if not provided
    if @notification_category.key.blank?
      @notification_category.key = NotificationCategory.generate_key(
        @notification_category.name,
        @notification_category.scope
      )
    end

    if @notification_category.save
      redirect_to admin_super_notification_categories_path,
        notice: "Notification category created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @notification_category.update(notification_category_params)
      redirect_to admin_super_notification_categories_path,
        notice: "Notification category updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notification_category.destroy
    redirect_to admin_super_notification_categories_path,
      notice: "Notification category deleted successfully."
  end

  private

  def set_notification_category
    @notification_category = NotificationCategory.find(params[:id])
  end

  def notification_category_params
    params.require(:notification_category).permit(
      :name, :key, :description, :icon, :color, :scope,
      :team_id, :enterprise_group_id, :active, :allow_user_disable,
      :default_priority, :send_email, :email_template
    )
  end
end
