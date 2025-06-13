class AuthTestController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def test_login
    if request.post?
      user = User.find_by(email: params[:email])
      if user && user.valid_password?(params[:password])
        sign_in(user)
        redirect_to root_path, notice: "Signed in successfully!"
      else
        redirect_to auth_test_test_login_path, alert: "Invalid credentials"
      end
    end
  end

  def test_logout
    sign_out(current_user) if user_signed_in?
    redirect_to root_path, notice: "Signed out successfully!"
  end
end