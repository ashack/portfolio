Rails.application.routes.draw do
  devise_for :users

  # Devise showcase (remove in production)
  get "devise_showcase", to: "devise_showcase#index" if Rails.env.development?

  # Auth debug (remove in production)
  get "auth_debug", to: "auth_debug#index" if Rails.env.development?

  # Auth test (remove in production)
  if Rails.env.development?
    get "auth_test/test_login", to: "auth_test#test_login"
    post "auth_test/test_login", to: "auth_test#test_login"
    delete "auth_test/test_logout", to: "auth_test#test_logout"
  end

  # Public Routes
  root "home#index"
  get "/pricing", to: "pages#pricing"
  get "/features", to: "pages#features"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Admin Routes
  namespace :admin do
    namespace :super do
      root "dashboard#index"

      resources :teams do
        member do
          patch :assign_admin
          patch :change_status
          delete :destroy
        end
      end

      resources :users do
        member do
          patch :promote_to_site_admin
          patch :demote_from_site_admin
          patch :set_status
          get :activity
          post :impersonate
        end
      end

      resources :settings, only: [ :index, :update ]
      resources :analytics, only: [ :index ]
    end

    namespace :site do
      root "dashboard#index"

      resources :users, only: [ :index, :show ] do
        member do
          patch :set_status
          get :activity
          post :impersonate
        end
      end

      resources :teams, only: [ :index, :show ]
      resources :support, only: [ :index, :show, :update ]
    end
  end

  # Direct User Routes
  scope "/dashboard" do
    root "users/dashboard#index", as: :user_dashboard

    namespace :users do
      resources :billing, only: [ :index, :show, :edit, :update ]
      resources :subscription, only: [ :show, :edit, :update, :destroy ]
      resources :profile, only: [ :show, :edit, :update ]
      resources :settings, only: [ :index, :update ]
    end
  end

  # Team Routes
  scope "/teams/:team_slug" do
    # Team member access
    root "teams/dashboard#index", as: :team_root

    namespace :teams do
      resources :profile, only: [ :show, :edit, :update ]
      resources :features # Team-specific features
    end

    # Team admin routes (for team admins only)
    scope "/admin" do
      get "/", to: "teams/admin/dashboard#index", as: :team_admin_root

      resources :members, controller: "teams/admin/members", as: :team_admin_members do
        member do
          patch :change_role
          delete :destroy
        end
      end

      resources :invitations, controller: "teams/admin/invitations", as: :team_admin_invitations do
        member do
          post :resend
          delete :revoke
        end
      end

      resources :billing, controller: "teams/admin/billing", as: :team_admin_billing, only: [ :index, :show ]
      resources :subscription, controller: "teams/admin/subscription", as: :team_admin_subscription, only: [ :show, :edit, :update, :destroy ]
      resources :settings, controller: "teams/admin/settings", as: :team_admin_settings, only: [ :index, :update ]
      resources :analytics, controller: "teams/admin/analytics", as: :team_admin_analytics, only: [ :index ]
    end
  end

  # Public Invitation Routes
  resources :invitations, only: [ :show ] do
    member do
      patch :accept
      patch :decline
    end
  end

  # Redirect after sign in based on user type
  get "/redirect_after_sign_in", to: "redirect#after_sign_in"
end
