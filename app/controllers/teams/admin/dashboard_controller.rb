class Teams::Admin::DashboardController < Teams::Admin::BaseController
  # Dashboard shows team's own data, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  def index
    @team_members = @team.users.order(created_at: :desc)
    @pending_invitations = @team.invitations.pending.active

    # Defensive programming for payment processor
    if @team.respond_to?(:payment_processor) && @team.payment_processor.present?
      @subscription = @team.payment_processor.subscription
    else
      @subscription = nil
    end

    @member_count = @team.member_count
    @member_limit = @team.max_members
  end
end
