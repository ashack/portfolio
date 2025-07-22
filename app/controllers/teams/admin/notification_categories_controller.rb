# Teams::Admin::NotificationCategoriesController - Team notification category management
#
# PURPOSE:
# - Manages team-specific notification categories and settings
# - Provides notification customization for team communications
# - Integrates with Noticed gem notification system
# - Allows team admins to create and manage notification types
#
# ACCESS LEVEL: Team Admin Only
# - Only team admins can create and manage notification categories
# - Team owners (direct users) have full notification management access
# - Invited admins can manage team notification settings
# - Regular team members cannot access notification administration
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/admin/notification_categories (index)
# - GET /teams/:team_slug/admin/notification_categories/new (new)
# - POST /teams/:team_slug/admin/notification_categories (create)
# - GET /teams/:team_slug/admin/notification_categories/:id/edit (edit)
# - PATCH /teams/:team_slug/admin/notification_categories/:id (update)
# - DELETE /teams/:team_slug/admin/notification_categories/:id (destroy)
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS (admin role): Can manage team notification categories
# - DIRECT USERS (team owners): Full notification category management
# - ENTERPRISE USERS: Cannot access (separate enterprise notification system)
#
# NOTIFICATION CATEGORY TYPES:
# - SYSTEM CATEGORIES: Read-only categories available to all teams
# - TEAM CATEGORIES: Custom categories created and managed by team admins
# - Dual-scope display with clear separation and permissions
#
# NOTIFICATION FEATURES:
# - Custom notification types for team-specific communications
# - Email template configuration for branded notifications
# - User preference controls (allow_user_disable)
# - Priority levels for notification importance
# - Icon and color customization for UI consistency
# - Integration with Noticed gem notification delivery
#
# BUSINESS RULES:
# - System categories are read-only for team admins
# - Team categories are fully manageable by team admins
# - Notification keys auto-generated to prevent conflicts
# - Team scope enforced for all category operations
# - Categories can be activated/deactivated without deletion
#
# SECURITY CONSIDERATIONS:
# - Admin-only access to notification category management
# - System categories protected from team admin modification
# - Team scope enforced (no cross-team category access)
# - Category creation logged for audit purposes
# - Proper error handling for system category access attempts
# - Parameter validation for security and data integrity
#
class Teams::Admin::NotificationCategoriesController < Teams::Admin::BaseController
  before_action :set_notification_category, only: [ :edit, :update, :destroy ]

  # NOTIFICATION CATEGORY LIST
  # Shows both system-wide and team-specific notification categories
  # System categories are read-only, team categories are fully manageable
  def index
    # Team admins can see system-wide categories (read-only) and their team's categories
    # System categories provide baseline notification types available to all teams
    @system_categories = NotificationCategory.system_wide
                                             .active
                                             .includes(:created_by)
                                             .order(:name)

    # Team categories are custom notification types created by team admins
    # These allow teams to customize their notification experience
    @team_categories = NotificationCategory.for_team(current_team)
                                           .includes(:created_by)
                                           .order(created_at: :desc)

    # Combine for pagination with system categories first (scope: :asc)
    # This provides a clear hierarchy with system categories at the top
    @notification_categories = NotificationCategory.where(
      id: @system_categories.pluck(:id) + @team_categories.pluck(:id)
    ).includes(:created_by).order(scope: :asc, created_at: :desc)

    @pagy, @notification_categories = pagy(@notification_categories, items: 20)
  end

  # NEW NOTIFICATION CATEGORY FORM
  # Creates new team-specific notification categories
  # Pre-configured with team scope and current user as creator
  def new
    @notification_category = current_team.notification_categories.build(
      scope: "team",
      created_by: current_user
    )
  end

  # CREATE NOTIFICATION CATEGORY
  # Processes new team notification category creation with auto-key generation
  # Ensures team scope and proper attribution
  def create
    @notification_category = current_team.notification_categories.build(notification_category_params)
    @notification_category.scope = "team"
    @notification_category.created_by = current_user

    # Auto-generate unique key if not provided to prevent conflicts
    # Team-specific prefix ensures no collision with system categories
    if @notification_category.key.blank?
      @notification_category.key = NotificationCategory.generate_key(
        @notification_category.name,
        "team_#{current_team.id}"
      )
    end

    if @notification_category.save
      redirect_to team_admin_notification_categories_path(team_slug: current_team.slug),
        notice: "Notification category created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # EDIT NOTIFICATION CATEGORY FORM
  # Displays editing form for team notification categories
  # System categories cannot be edited by team admins
  def edit
    # @notification_category loaded by set_notification_category with security checks
  end

  # UPDATE NOTIFICATION CATEGORY
  # Updates team notification category settings and configuration
  # Validates parameters and maintains team scope
  def update
    if @notification_category.update(notification_category_params)
      redirect_to team_admin_notification_categories_path(team_slug: current_team.slug),
        notice: "Notification category updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE NOTIFICATION CATEGORY
  # Removes team notification categories (system categories cannot be deleted)
  # Performs hard delete - consider soft delete for data preservation
  def destroy
    @notification_category.destroy
    redirect_to team_admin_notification_categories_path(team_slug: current_team.slug),
      notice: "Notification category deleted successfully."
  end

  private

  # NOTIFICATION CATEGORY LOOKUP
  # Securely loads notification categories with team scope and permission checks
  # Prevents modification of system categories by team admins
  def set_notification_category
    # Allow editing of team categories only - team scope enforced
    @notification_category = current_team.notification_categories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # If not found in team categories, check if it's a system category (view only)
    # This prevents errors while clearly communicating permission restrictions
    @notification_category = NotificationCategory.system_wide.find(params[:id])
    redirect_to team_admin_notification_categories_path(team_slug: current_team.slug),
      alert: "System categories cannot be modified by team admins."
  end

  # NOTIFICATION CATEGORY PARAMETERS
  # Filters allowed parameters for notification category creation and updates
  # Includes all configurable options for comprehensive notification control
  def notification_category_params
    params.require(:notification_category).permit(
      :name, :description, :icon, :color, :active,
      :allow_user_disable, :default_priority, :send_email, :email_template
    )
  end

  # TEAM ACCESSOR
  # Helper method to access current team consistently
  # Used for team scope validation and category association
  def current_team
    @team
  end
end
