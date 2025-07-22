# Teams::Admin::DashboardController - Team administration dashboard
#
# PURPOSE:
# - Provides comprehensive team administration overview for team admins
# - Displays key team metrics, member statistics, and administrative controls
# - Serves as central hub for team management activities
# - Shows billing status, member limits, and pending invitations
#
# ACCESS LEVEL: Team Admin Only
# - Restricted to users with team_admin? = true
# - Team owners (direct users) have full administrative dashboard access
# - Invited admins see delegated administrative information
# - Regular team members redirected to regular team dashboard
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/admin (team_admin_root_path)
# - Central landing page for all team administrative functions
# - Links to member management, billing, invitations, and settings
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS (admin role): Administrative dashboard for teams they admin
# - DIRECT USERS (team owners): Full administrative control for teams they own
# - ENTERPRISE USERS: Cannot access (separate enterprise admin dashboard)
#
# DASHBOARD FEATURES:
# - Team member overview with creation timestamps
# - Pending invitation tracking and management
# - Subscription status and billing information
# - Member count vs. plan limits monitoring
# - Quick access to administrative functions
# - Team health and activity metrics
#
# BILLING INTEGRATION:
# - Subscription status display with graceful error handling
# - Member count tracking against plan limits
# - Billing status indicators for team health
# - Payment processor availability checks
#
# SECURITY CONSIDERATIONS:
# - Admin-only access to sensitive team information
# - Defensive programming for payment processor failures
# - No cross-team administrative access (team scope enforced)
# - Member count validation against subscription limits
# - Graceful degradation when external services unavailable
#
class Teams::Admin::DashboardController < Teams::Admin::BaseController
  # Dashboard shows team's own data, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  # TEAM ADMIN DASHBOARD
  # Central administrative overview providing key team metrics and management access
  # Includes member management, billing status, and invitation tracking
  def index
    # Load all team members ordered by join date (most recent first)
    # Used for member management and onboarding tracking
    @team_members = @team.users.order(created_at: :desc)

    # Track pending invitations that haven't been accepted yet
    # Active invitations that haven't expired (within invitation validity period)
    @pending_invitations = @team.invitations.pending.active

    # Defensive programming for payment processor integration
    # Handles cases where Stripe/Pay gem integration may not be fully configured
    if @team.respond_to?(:payment_processor) && @team.payment_processor.present?
      @subscription = @team.payment_processor.subscription
    else
      @subscription = nil
    end

    # Team capacity and growth metrics
    # Critical for subscription management and plan compliance
    @member_count = @team.member_count
    @member_limit = @team.max_members
  end
end
