class Users::BaseController < ApplicationController
  before_action :require_direct_user!
  layout "user"

  private

  def require_direct_user!
    unless current_user&.direct?
      flash[:alert] = "This area is only accessible to direct users."
      redirect_to root_path
    end
  end
end
