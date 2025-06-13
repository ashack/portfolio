class Teams::Admin::SettingsController < Teams::Admin::BaseController
  # Skip Pundit verification since settings shows team's own data
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized

  def index
    # @team is already set by the base controller
  end

  def update
    if @team.update(team_params)
      redirect_to team_admin_settings_path, notice: "Team settings updated successfully."
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def team_params
    params.require(:team).permit(:name, :description, :timezone, :website)
  end
end
