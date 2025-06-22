class Admin::Site::SupportController < Admin::Site::BaseController
  # Skip policy scoping since we're showing support dashboard, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  def index
    # Support dashboard with user issues and team inquiries
    recent_user_issues = User.where(status: [ "inactive", "locked" ]).order(updated_at: :desc)
    @pagy_issues, @recent_user_issues = pagy(recent_user_issues, page_param: :issues_page, items: 10)
    
    teams_needing_attention = Team.where(status: [ "suspended", "cancelled" ]).order(updated_at: :desc)
    @pagy_teams, @teams_needing_attention = pagy(teams_needing_attention, page_param: :teams_page, items: 10)
    
    recent_failed_logins = User.where("failed_attempts > 0").order(updated_at: :desc)
    @pagy_failed, @recent_failed_logins = pagy(recent_failed_logins, page_param: :failed_page, items: 10)
  end

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
