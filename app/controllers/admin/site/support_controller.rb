# Site Admin Support Controller
#
# PURPOSE:
# Provides specialized support dashboard and tools for site administrators to help customers.
# Focuses on user issues, account problems, and organizational support needs.
#
# ACCESS RESTRICTIONS:
# - Site admins have limited support actions (unlock, activate, reactivate)
# - Cannot delete users or access billing information
# - Cannot create teams or enterprise groups
# - Inherits from Admin::Site::BaseController which enforces site_admin role
#
# BUSINESS RULES:
# - Site admins provide first-level customer support
# - Can resolve common account issues (locked accounts, inactive users)
# - Can reactivate suspended teams (basic support action)
# - No destructive actions or financial access
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Supports all user types (direct, team members, enterprise)
# - Understands organizational context for team and enterprise support
# - No crossover capabilities between user types
class Admin::Site::SupportController < Admin::Site::BaseController
  # Skip policy scoping since we're showing support dashboard, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  # Main support dashboard showing prioritized customer issues requiring attention
  #
  # SUPPORT CATEGORIES:
  # - User Issues: Inactive and locked accounts needing help
  # - Team Issues: Suspended or cancelled teams needing attention
  # - Security Issues: Users with failed login attempts
  #
  # PRIORITIZATION:
  # - Most recent issues first (updated_at desc)
  # - Limited to 10 items per category for focus
  # - Separate pagination for each issue type
  #
  # SUPPORT WORKFLOW:
  # - Identifies users who need account unlocking
  # - Shows teams that may need reactivation
  # - Highlights potential security concerns with failed logins
  #
  # PERFORMANCE:
  # - Uses separate queries for different issue types
  # - Paginated to prevent dashboard overload
  def index
    # Support dashboard with user issues and team inquiries
    recent_user_issues = User.where(status: [ "inactive", "locked" ]).order(updated_at: :desc)
    @pagy_issues, @recent_user_issues = pagy(recent_user_issues, page_param: :issues_page, items: 10)

    teams_needing_attention = Team.where(status: [ "suspended", "cancelled" ]).order(updated_at: :desc)
    @pagy_teams, @teams_needing_attention = pagy(teams_needing_attention, page_param: :teams_page, items: 10)

    recent_failed_logins = User.where("failed_attempts > 0").order(updated_at: :desc)
    @pagy_failed, @recent_failed_logins = pagy(recent_failed_logins, page_param: :failed_page, items: 10)
  end

  # Display individual support case details for user or team
  #
  # SUPPORT CASE ROUTING:
  # - "user-{id}" pattern: Individual user support case
  # - "team-{id}" pattern: Team-related support case
  # - Invalid patterns redirect to support index
  #
  # CONTEXT PROVIDED:
  # - @support_subject: The user or team needing support
  # - @support_type: "user" or "team" for view customization
  #
  # USE CASES:
  # - Deep dive into specific user account issues
  # - Detailed team support and member management context
  # - Historical context for recurring support issues
  #
  # SECURITY:
  # - Uses find() which will raise 404 if record doesn't exist
  # - No authorization bypass - still subject to site admin restrictions
  def show
    # Individual support case - could be user or team related
    case params[:id]
    when /^user-(.+)$/
      @support_subject = User.find($1)
      @support_type = "user"
    when /^team-(.+)$/
      @support_subject = Team.find($1)
      @support_type = "team"
    else
      redirect_to admin_site_support_index_path, alert: "Support case not found"
      nil
    end
  end

  # Process support actions that site admins can perform
  #
  # ALLOWED SUPPORT ACTIONS:
  # - unlock_user: Reset failed login attempts and unlock account
  # - activate_user: Change user status from inactive to active
  # - reactivate_team: Change team status from suspended/cancelled to active
  #
  # SECURITY CONSTRAINTS:
  # - Site admins can only perform basic support actions
  # - No destructive actions (delete users, access billing)
  # - No role changes or system-level modifications
  # - Actions logged implicitly through model callbacks
  #
  # BUSINESS RULES:
  # - Unlock user: Clears Devise lockable fields (failed_attempts, locked_at)
  # - Activate user: Changes status to allow login and platform access
  # - Reactivate team: Restores team access for members
  #
  # AUDIT TRAIL:
  # - Actions redirect with success/failure messages
  # - User and team updates trigger model-level audit logging
  # - Support context preserved in redirect URLs
  def update
    # Handle support actions
    case params[:action_type]
    when "unlock_user"
      user = User.find(params[:user_id])
      user.update(failed_attempts: 0, locked_at: nil)
      redirect_to admin_site_support_path("user-#{user.id}"), notice: "User account unlocked successfully"
    when "activate_user"
      user = User.find(params[:user_id])
      user.update(status: "active")
      redirect_to admin_site_support_path("user-#{user.id}"), notice: "User account activated successfully"
    when "reactivate_team"
      team = Team.find(params[:team_id])
      team.update(status: "active")
      redirect_to admin_site_support_path("team-#{team.id}"), notice: "Team reactivated successfully"
    else
      redirect_to admin_site_support_index_path, alert: "Invalid support action"
    end
  end
end
