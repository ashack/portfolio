class Enterprise::Admin::NotificationCategoriesController < Enterprise::Admin::BaseController
  before_action :set_notification_category, only: [:edit, :update, :destroy]
  
  def index
    # Enterprise admins can see system-wide categories (read-only) and their enterprise's categories
    @system_categories = NotificationCategory.system_wide
                                             .active
                                             .includes(:created_by)
                                             .order(:name)
    
    @enterprise_categories = NotificationCategory.for_enterprise(current_enterprise_group)
                                                 .includes(:created_by)
                                                 .order(created_at: :desc)
    
    # Combine for pagination
    @notification_categories = NotificationCategory.where(
      id: @system_categories.pluck(:id) + @enterprise_categories.pluck(:id)
    ).includes(:created_by).order(scope: :asc, created_at: :desc)
    
    @pagy, @notification_categories = pagy(@notification_categories, items: 20)
  end
  
  def new
    @notification_category = current_enterprise_group.notification_categories.build(
      scope: 'enterprise',
      created_by: current_user
    )
  end
  
  def create
    @notification_category = current_enterprise_group.notification_categories.build(notification_category_params)
    @notification_category.scope = 'enterprise'
    @notification_category.created_by = current_user
    
    # Auto-generate key if not provided
    if @notification_category.key.blank?
      @notification_category.key = NotificationCategory.generate_key(
        @notification_category.name,
        "enterprise_#{current_enterprise_group.id}"
      )
    end
    
    if @notification_category.save
      redirect_to enterprise_admin_notification_categories_path(enterprise_slug: current_enterprise_group.slug), 
        notice: 'Notification category created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @notification_category.update(notification_category_params)
      redirect_to enterprise_admin_notification_categories_path(enterprise_slug: current_enterprise_group.slug), 
        notice: 'Notification category updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @notification_category.destroy
    redirect_to enterprise_admin_notification_categories_path(enterprise_slug: current_enterprise_group.slug), 
      notice: 'Notification category deleted successfully.'
  end
  
  private
  
  def set_notification_category
    # Allow editing of enterprise categories only
    @notification_category = current_enterprise_group.notification_categories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # If not found in enterprise categories, check if it's a system category (view only)
    @notification_category = NotificationCategory.system_wide.find(params[:id])
    redirect_to enterprise_admin_notification_categories_path(enterprise_slug: current_enterprise_group.slug), 
      alert: 'System categories cannot be modified by enterprise admins.'
  end
  
  def notification_category_params
    params.require(:notification_category).permit(
      :name, :description, :icon, :color, :active, 
      :allow_user_disable, :default_priority, :send_email, :email_template
    )
  end
end