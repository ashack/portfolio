class Teams::Admin::DashboardController < Teams::Admin::BaseController
  def index
    @team_members = @team.users.order(created_at: :desc)
    @pending_invitations = @team.invitations.pending.active
    @subscription = @team.payment_processor&.subscription
    @member_count = @team.member_count
    @member_limit = @team.max_members
  end
end
