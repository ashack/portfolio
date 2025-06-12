class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  
  def pricing
    @individual_plans = Plan.active.for_individuals
    @team_plans = Plan.active.for_teams
  end
  
  def features
  end
end