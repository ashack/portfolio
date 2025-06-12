class Teams::BaseController < ApplicationController
  layout 'team'
  before_action :require_team_member!
  before_action :set_team
  
  private
  
  def require_team_member!
    unless current_user&.invited?
      flash[:alert] = "You must be a team member to access this area."
      redirect_to root_path
    end
  end
  
  def set_team
    @team = Team.find_by!(slug: params[:team_slug])
    
    unless current_user.team_id == @team.id
      flash[:alert] = "You don't have access to this team."
      redirect_to root_path
    end
  end
end