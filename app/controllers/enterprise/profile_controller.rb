class Enterprise::ProfileController < ApplicationController
  include EmailChangeProtection

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
      redirect_to profile_path(enterprise_group_slug: @enterprise_group.slug, id: @user), notice: "Profile updated successfully."
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
    # EmailChangeProtection concern will handle email change attempts
    params.require(:user).permit(
      :first_name, :last_name, :bio, :phone_number, :avatar_url, :avatar,
      :timezone, :locale, :profile_visibility,
      :linkedin_url, :twitter_url, :github_url, :website_url,
      notification_preferences: {}
    )
  end
end
