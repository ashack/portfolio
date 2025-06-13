class Admin::Site::TeamsController < Admin::Site::BaseController
  before_action :set_team, only: [ :show ]

  def index
    @teams = policy_scope(Team).order(created_at: :desc)
    @pagy, @teams = pagy(@teams)
  end

  def show
    authorize @team
  end

  private

  def set_team
    @team = Team.find_by!(slug: params[:id])
  end
end
