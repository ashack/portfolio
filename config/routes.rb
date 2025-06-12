Rails.application.routes.draw do
  devise_for :users

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

    # Team admin routes
    scope "/admin" do
      root "teams/admin/dashboard#index", as: :team_admin_root

      namespace :teams, path: "" do
        namespace :admin do
          resources :members do
            member do
              patch :change_role
              delete :destroy # Complete account deletion
            end
          end

          resources :invitations do
            member do
              post :resend
              delete :revoke
            end
          end

          resources :billing, only: [ :index, :show ]
          resources :subscription, only: [ :show, :edit, :update, :destroy ]
          resources :settings, only: [ :index, :update ]
          resources :analytics, only: [ :index ]
        end
      end
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
