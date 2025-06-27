require "test_helper"

class EmailChangeProtectionTest < ActionDispatch::IntegrationTest
  class TestController < ApplicationController
    include EmailChangeProtection
    
    def update
      # Simulate a controller action that updates user
      if current_user.update(user_params)
        redirect_to root_path, notice: "Updated successfully"
      else
        render plain: "Error", status: :unprocessable_entity
      end
    end
    
    private
    
    def user_params
      params.require(:user).permit(:first_name, :email)
    end
  end
  
  def setup
    @user = sign_in_with(
      email: "test@example.com",
      first_name: "Test",
      last_name: "User"
    )
    
    # Set up test routes
    Rails.application.routes.draw do
      devise_for :users
      patch "/test_update", to: "email_change_protection_test/test#update"
      root to: "home#index"
    end
  end
  
  def teardown
    # Reset routes after test
    Rails.application.reload_routes!
  end
  
  test "concern detects email change attempt" do
    patch "/test_update", params: {
      user: {
        first_name: "Updated",
        email: "new@example.com"
      }
    }
    
    assert_redirected_to root_path
    assert_equal "Updated successfully", flash[:notice]
    assert_equal "Email changes must be requested through the email change request system for security reasons.", flash[:alert]
    
    @user.reload
    assert_equal "test@example.com", @user.email
    assert_equal "Updated", @user.first_name
  end
  
  test "concern removes email and unconfirmed_email from params" do
    patch "/test_update", params: {
      user: {
        first_name: "Updated",
        email: "attacker@example.com",
        unconfirmed_email: "attacker@example.com"
      }
    }
    
    assert_redirected_to root_path
    
    @user.reload
    assert_equal "test@example.com", @user.email
    assert_nil @user.unconfirmed_email
  end
  
  test "concern only triggers when email is different" do
    patch "/test_update", params: {
      user: {
        first_name: "Updated",
        email: @user.email # Same email
      }
    }
    
    assert_redirected_to root_path
    assert_equal "Updated successfully", flash[:notice]
    assert_nil flash[:alert] # No warning since email didn't change
  end
  
  test "concern handles various param structures" do
    # Test with symbol keys
    patch "/test_update", params: {
      user: {
        email: "new@example.com"
      }
    }
    
    @user.reload
    assert_equal "test@example.com", @user.email
  end
  
  test "concern logs security warning" do
    logs = []
    Rails.logger.stub :warn, ->(msg) { logs << msg } do
      patch "/test_update", params: {
        user: {
          email: "attacker@example.com"
        }
      }
    end
    
    assert logs.any? { |log| log.include?("[SECURITY] Email change attempt blocked") }
    assert logs.any? { |log| log.include?("Attempted email: attacker@example.com") }
  end
end