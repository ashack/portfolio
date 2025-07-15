class Admin::Super::TeamsController < ApplicationController
  include ActivityTrackable
  include Paginatable

  before_action :require_admin!
  before_action :set_team, only: [ :show, :edit, :update, :assign_admin, :change_status, :destroy ]

  def index
    @teams = policy_scope(Team).includes(:admin, :created_by, :users).order(created_at: :desc)
    @pagy, @teams = pagy(@teams, items: @items_per_page, page: @page)
  end

  def show
    authorize @team
  end

  def new
    @team = Team.new
    authorize @team
  end

  def create
    @team = Team.new(team_params)
    authorize @team

    service = Teams::CreationService.new(current_user, team_params, User.find_by(id: params[:admin_id]))
    result = service.call

    if result.success?
      redirect_to admin_super_team_path(result.team), notice: "Team was successfully created."
    else
      flash.now[:alert] = result.error
      render :new
    end
  end

  def edit
    authorize @team
  end

  def update
    authorize @team
    if @team.update(team_params)
      redirect_to admin_super_team_path(@team), notice: "Team was successfully updated."
    else
      render :edit
    end
  end

  def assign_admin
    authorize @team
    new_admin = User.find(params[:admin_id])

    if @team.update(admin: new_admin)
      # Handle direct users who will own the team
      if new_admin.direct?
        new_admin.update!(team: @team, team_role: "admin", owns_team: true)
      else
        # Invited users just manage the team
        new_admin.update!(team: @team, team_role: "admin")
      end
      redirect_to admin_super_team_path(@team), notice: "Team admin was successfully assigned."
    else
      redirect_to admin_super_team_path(@team), alert: "Failed to assign team admin."
    end
  end

  def change_status
    authorize @team
    if @team.update(status: params[:status])
      redirect_to admin_super_team_path(@team), notice: "Team status was successfully updated."
    else
      redirect_to admin_super_team_path(@team), alert: "Failed to update team status."
    end
  end

  def destroy
    authorize @team
    @team.destroy
    redirect_to admin_super_teams_path, notice: "Team was successfully deleted."
  end

  private

  def require_admin!
    unless current_user&.super_admin? || current_user&.site_admin?
      flash[:alert] = "You must be an admin to access this area."
      redirect_to root_path
    end
  end

  def set_team
    @team = Team.find_by!(slug: params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :slug, :plan, :status, :max_members, :custom_domain, :admin_id, :trial_ends_at)
  end
end
