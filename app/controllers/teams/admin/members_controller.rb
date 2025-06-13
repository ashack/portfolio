class Teams::Admin::MembersController < Teams::Admin::BaseController
  before_action :set_member, only: [ :show, :change_role, :destroy ]

  def index
    @members = @team.users.order(created_at: :desc)
    @pagy, @members = pagy(@members)
    skip_policy_scope
  end

  def show
    authorize @member
  end

  def change_role
    authorize @member

    if @member.update(team_role: params[:role])
      redirect_to team_admin_members_path(team_slug: @team.slug), notice: "Member role was successfully updated."
    else
      redirect_to team_admin_members_path(team_slug: @team.slug), alert: "Failed to update member role."
    end
  end

  def destroy
    authorize @member

    if @member == current_user
      redirect_to team_admin_members_path(team_slug: @team.slug), alert: "You cannot delete yourself."
    elsif @member.destroy
      redirect_to team_admin_members_path(team_slug: @team.slug), notice: "Member was successfully removed from the team."
    else
      redirect_to team_admin_members_path(team_slug: @team.slug), alert: "Failed to remove member."
    end
  end

  private

  def set_member
    @member = @team.users.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Member not found: #{e.message}"
    redirect_to team_admin_members_path(team_slug: @team.slug), alert: "Member not found." and return
  end
end
