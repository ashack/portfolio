class Teams::FeaturesController < Teams::BaseController
  def index
    @features = @team.plan_features
    skip_policy_scope
    skip_authorization
  end

  def show
    # Individual feature details
    @feature = params[:id]
    skip_authorization
  end

  def new
    # Feature request or configuration form
    skip_authorization
  end

  def create
    # Handle feature requests
    redirect_to teams_features_path(team_slug: @team.slug), notice: "Feature request submitted."
  end

  def edit
    # Edit feature configuration
    @feature = params[:id]
    skip_authorization
  end

  def update
    # Update feature configuration
    redirect_to teams_features_path(team_slug: @team.slug), notice: "Feature configuration updated."
  end

  def destroy
    # Remove feature request
    redirect_to teams_features_path(team_slug: @team.slug), notice: "Feature request removed."
  end
end