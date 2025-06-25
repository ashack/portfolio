class Enterprise::ProfileController < ApplicationController
  before_action :authenticate_user!
  before_action :require_enterprise_user!
  before_action :set_enterprise_group
  skip_after_action :verify_authorized

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      # Calculate profile completion after update
      @user.calculate_profile_completion
      redirect_to enterprise_profile_path(@enterprise_group.slug), notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_enterprise_user!
    redirect_to root_path, alert: "Access denied." unless current_user.enterprise?
  end

  def set_enterprise_group
    @enterprise_group = current_user.enterprise_group
  end

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :bio, :phone_number, :avatar_url,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url,
      notification_preferences: {}
    )
  end
end
