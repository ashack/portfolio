# Enterprise::DashboardController
#
# Main dashboard controller for enterprise users within the triple-track SaaS system.
# Provides the primary entry point and overview for enterprise organizations,
# displaying organization information and member status.
#
# **Access Control:**
# - Available to ALL enterprise users (both admins and members)
# - Inherits enterprise user validation from Enterprise::BaseController
# - Does not require admin privileges (unlike billing/settings)
#
# **Dashboard Features for All Enterprise Users:**
# - Organization overview and member list
# - Role-based UI elements (admin vs member views)
# - Navigation to other enterprise areas based on permissions
# - Enterprise-specific branding and theme (purple color scheme)
#
# **Admin vs Member Views:**
# - Enterprise Admins: See admin controls, member management links, billing access
# - Enterprise Members: See basic dashboard, limited navigation options
# - Role detection via current_user.enterprise_admin? method
#
# **Enterprise System Context:**
# - Completely isolated from direct user dashboards (/dashboard)
# - Separate from team dashboards (/teams/:slug/)
# - Uses enterprise-specific URL structure (/enterprise/:slug/)
# - Enforces multi-tenant isolation via enterprise group slug
#
# **Data Loading:**
# - Loads enterprise group members with optimized includes
# - Checks current user's admin status for conditional UI rendering
# - Minimal data loading for fast dashboard performance
#
# **URL Structure:**
# Primary route: /enterprise/:enterprise_group_slug/
# - Serves as the landing page after enterprise user login
# - Enterprise group slug identifies the organization context
class Enterprise::DashboardController < Enterprise::BaseController
  # Skip Pundit policy verification since this is a dashboard overview
  skip_after_action :verify_policy_scoped, only: [ :index ]
  skip_after_action :verify_authorized, only: [ :index ]

  # Main enterprise dashboard displaying organization overview
  #
  # **Functionality:**
  # - Shows enterprise group information and member list
  # - Determines user's role (admin vs member) for UI rendering
  # - Provides navigation entry point to other enterprise features
  #
  # **Data Loading Strategy:**
  # - Includes :enterprise_group association to prevent N+1 queries
  # - Loads all members for organization overview
  # - Calculates admin status for conditional UI elements
  #
  # **UI Differentiation:**
  # - Admin users see: member management, billing, settings links
  # - Member users see: basic dashboard, profile management only
  # - Consistent enterprise branding across all role views
  def index
    # Load all enterprise group members with optimized query
    @members = @enterprise_group.users.includes(:enterprise_group)
    
    # Determine if current user has admin privileges for UI rendering
    @is_admin = current_user.enterprise_admin?
  end
end
