class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def pricing
    @individual_plans = Plan.active.for_individuals
    @team_plans = Plan.active.for_teams
  end

  def features
  end
end
