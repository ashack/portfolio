# Enterprise::Admin::NotificationCategoriesController
#
# Manages notification categories for enterprise organizations within the triple-track SaaS system.
# Handles enterprise-specific notification category management, allowing enterprise admins to
# create custom notification categories while viewing system-wide categories (read-only).
#
# **Access Control:**
# - RESTRICTED to Enterprise Admins only (enterprise_group_role: 'admin')
# - Enterprise Members cannot access notification category management
# - Inherits enterprise admin validation from Enterprise::Admin::BaseController
# - Completely separate from team and direct user notification management
#
# **Notification System Architecture:**
# - System Categories: Created by Super Admins, visible to all (read-only)
# - Enterprise Categories: Created by Enterprise Admins, specific to their organization
# - Team Categories: Managed separately in team admin interfaces
# - Direct User Categories: System-wide categories only (no custom categories)
#
# **Enterprise vs System Categories:**
# - Enterprise Admins can VIEW system categories but cannot modify them
# - Enterprise Admins can CREATE, EDIT, DELETE their own enterprise categories
# - Enterprise categories are scoped to the specific enterprise organization
# - Enterprise categories inherit from NotificationCategory with scope: 'enterprise'
#
# **Category Management Features:**
# - Custom notification categories for enterprise-specific workflows
# - Icon and color customization with enterprise branding
# - Email template customization for enterprise notifications
# - Priority levels and user disable permissions
# - Integration with enterprise member notification preferences
#
# **Multi-Tenancy:**
# - Categories are isolated per enterprise group via current_enterprise_group
# - Enterprise slug in URLs maintains context and security
# - No cross-enterprise category access or visibility
#
# **Integration with Notification System:**
# - Uses Noticed gem for notification delivery
# - Categories define templates, priorities, and delivery methods
# - Enterprise members can customize preferences per category
# - Supports email notifications with enterprise branding
#
# **URL Structure:**
# All routes under /enterprise/:enterprise_slug/admin/notification_categories/
# - Enterprise admin area for notification category management
# - Multi-tenant isolation via enterprise slug parameter
class Enterprise::Admin::NotificationCategoriesController < Enterprise::Admin::BaseController
  # Load notification category for specific actions
  before_action :set_notification_category, only: [ :edit, :update, :destroy ]

  # Lists notification categories available to enterprise admins
  #
  # **Category Display Logic:**
  # - System Categories: Read-only view of platform-wide categories
  # - Enterprise Categories: Full management capabilities for organization-specific categories
  # - Combined display with clear visual distinction between system and enterprise categories
  #
  # **Data Loading Strategy:**
  # - Loads system categories with active status filter
  # - Loads enterprise-specific categories for current organization
  # - Combines both types for unified pagination and display
  # - Includes :created_by for audit trail and attribution
  #
  # **Sorting and Organization:**
  # - System categories displayed first (by name)
  # - Enterprise categories displayed second (by creation date, newest first)
  # - Paginated display for performance with large category lists
  def index
    # Enterprise admins can see system-wide categories (read-only) and their enterprise's categories
    @system_categories = NotificationCategory.system_wide
                                             .active
                                             .includes(:created_by)
                                             .order(:name)

    @enterprise_categories = NotificationCategory.for_enterprise(current_enterprise_group)
                                                 .includes(:created_by)
                                                 .order(created_at: :desc)

    # Combine for pagination with system categories first, then enterprise categories
    @notification_categories = NotificationCategory.where(
      id: @system_categories.pluck(:id) + @enterprise_categories.pluck(:id)
    ).includes(:created_by).order(scope: :asc, created_at: :desc)

    @pagy, @notification_categories = pagy(@notification_categories, items: 20)
  end

  # New enterprise notification category form
  #
  # **Category Creation:**
  # - Creates enterprise-scoped notification category
  # - Pre-populates scope as 'enterprise' (cannot be changed)
  # - Associates category with current enterprise group
  # - Sets current admin user as creator for audit trail
  #
  # **Default Values:**
  # - Scope: 'enterprise' (identifies category as enterprise-specific)
  # - Created By: Current enterprise admin user
  # - Enterprise Group: Current enterprise organization
  def new
    @notification_category = current_enterprise_group.notification_categories.build(
      scope: "enterprise",
      created_by: current_user
    )
  end

  # Creates new enterprise notification category
  #
  # **Creation Process:**
  # 1. Builds category associated with current enterprise group
  # 2. Sets scope to 'enterprise' (enforces enterprise isolation)
  # 3. Records creating admin for audit trail
  # 4. Auto-generates unique key if not provided
  # 5. Validates all fields according to enterprise standards
  #
  # **Key Generation:**
  # - Auto-generates key based on category name and enterprise ID
  # - Format: sanitized_name_enterprise_123
  # - Ensures uniqueness within enterprise context
  # - Prevents key conflicts with system categories
  #
  # **Validation:**
  # - Name: Required, unique within enterprise scope
  # - Description: Optional but recommended for clarity
  # - Icon/Color: Enterprise branding consistency
  # - Email template: Enterprise-specific messaging
  def create
    @notification_category = current_enterprise_group.notification_categories.build(notification_category_params)
    @notification_category.scope = "enterprise"
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
        notice: "Notification category created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Edit form for enterprise notification category
  #
  # **Editing Restrictions:**
  # - Can only edit enterprise categories (not system categories)
  # - Must belong to current enterprise group
  # - Cannot change scope (remains 'enterprise')
  # - Key field typically locked after creation
  def edit
    # Edit form for enterprise-scoped notification category
  end

  # Updates enterprise notification category
  #
  # **Update Process:**
  # - Validates all changes according to enterprise standards
  # - Maintains enterprise scope and associations
  # - Updates notification preferences for existing enterprise members
  # - Preserves audit trail with update timestamps
  #
  # **Business Rules:**
  # - Cannot change category scope after creation
  # - Cannot reassign to different enterprise group
  # - Key changes require careful validation (may break existing notifications)
  # - Deactivating categories affects member notification preferences
  def update
    if @notification_category.update(notification_category_params)
      redirect_to enterprise_admin_notification_categories_path(enterprise_slug: current_enterprise_group.slug),
        notice: "Notification category updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Deletes enterprise notification category
  #
  # **Deletion Logic:**
  # - Can only delete enterprise categories (not system categories)
  # - Removes category and associated notification preferences
  # - May affect existing notifications using this category
  # - Irreversible action requiring admin confirmation
  #
  # **Impact Assessment:**
  # - Existing notifications using this category remain but lose category association
  # - Member notification preferences for this category are removed
  # - Email templates and branding associated with category are lost
  # - Consider deactivation instead of deletion for active categories
  def destroy
    @notification_category.destroy
    redirect_to enterprise_admin_notification_categories_path(enterprise_slug: current_enterprise_group.slug),
      notice: "Notification category deleted successfully."
  end

  private

  # Finds and validates notification category for editing
  #
  # **Security and Scoping:**
  # - First attempts to find category within current enterprise group
  # - If not found in enterprise scope, checks if it's a system category
  # - Blocks modification attempts on system categories
  # - Redirects with error for unauthorized access attempts
  #
  # **Error Handling:**
  # - Enterprise categories: Allows normal editing operations
  # - System categories: Blocks editing with informative error message
  # - Non-existent categories: Raises standard ActiveRecord::RecordNotFound
  def set_notification_category
    # Allow editing of enterprise categories only
    @notification_category = current_enterprise_group.notification_categories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # If not found in enterprise categories, check if it's a system category (view only)
    @notification_category = NotificationCategory.system_wide.find(params[:id])
    redirect_to enterprise_admin_notification_categories_path(enterprise_slug: current_enterprise_group.slug),
      alert: "System categories cannot be modified by enterprise admins."
  end

  # Strong parameters for notification category management
  #
  # **Permitted Fields:**
  # - name: Category display name (used in UI and notifications)
  # - description: Detailed explanation of category purpose
  # - icon: Icon identifier for UI display (enterprise icon set)
  # - color: Category color for branding consistency
  # - active: Enable/disable category for use
  # - allow_user_disable: Whether enterprise members can disable this category
  # - default_priority: Default notification priority level
  # - send_email: Whether this category triggers email notifications
  # - email_template: Custom email template for enterprise branding
  #
  # **Restricted Fields:**
  # - scope: Automatically set to 'enterprise' (cannot be changed)
  # - key: Auto-generated or carefully managed (not in permitted params)
  # - created_by: Set automatically to current admin user
  def notification_category_params
    params.require(:notification_category).permit(
      :name, :description, :icon, :color, :active,
      :allow_user_disable, :default_priority, :send_email, :email_template
    )
  end
end
