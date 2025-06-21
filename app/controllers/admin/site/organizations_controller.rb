class Admin::Site::OrganizationsController < Admin::Site::BaseController
  def index
    @tab = params[:tab] || "teams"  # Default to teams tab

    # Always get counts for tabs
    @teams = policy_scope(Team).includes(:admin, :users).order(created_at: :desc)
    @enterprise_groups = policy_scope(EnterpriseGroup).includes(:admin, :users).order(created_at: :desc)

    # Filter based on tab
    case @tab
    when "enterprise"
      @show_teams = false
      @show_enterprise_groups = true
    else # "teams" (default)
      @show_teams = true
      @show_enterprise_groups = false
    end

    # Combined stats (always calculated)
    @total_organizations = @teams.count + @enterprise_groups.count
    @active_teams = @teams.active.count
    @active_enterprise_groups = @enterprise_groups.active.count
    @total_members = @teams.joins(:users).count + @enterprise_groups.joins(:users).count
    @paid_teams = @teams.where.not(plan: "starter").count
  end
end
