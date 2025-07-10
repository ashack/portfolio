Rails.application.routes.draw do
  # Mount Blazer for analytics (admin only)
  authenticate :user, ->(user) { user.admin? } do
    mount Blazer::Engine, at: "blazer"
  end

  # Test route for form styling
  get "/test_form", to: proc { |env| [ 200, { "Content-Type" => "text/html" }, [ ApplicationController.render(template: "test_form", layout: false) ] ] }
  # CSP violation reports endpoint
  post "/csp_violation_reports", to: "csp_reports#create"

  # Email Change Requests
  resources :email_change_requests, only: [ :index, :new, :create, :show ], param: :token

  # Notifications
  resources :notifications, only: [ :index ] do
    member do
      patch :mark_as_read
      delete :destroy
    end
    collection do
      patch :mark_all_as_read
      delete :destroy_all
    end
  end

  # API endpoints
  namespace :api do
    resources :notifications, only: [ :index ] do
      member do
        patch :mark_as_read
      end
      collection do
        get :unread_count
        patch :mark_all_as_read
      end
    end
  end

  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

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
  get "/choose-plan-type", to: "pages#choose_plan_type", as: :choose_plan_type
  get "/contact-sales", to: "pages#contact_sales", as: :contact_sales

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
          post :reset_password
          post :confirm_email
          post :resend_confirmation
          post :unlock_account
        end
      end

      resource :settings, only: [ :show, :update ]
      resources :analytics, only: [ :index ]
      resources :plans
      resources :notifications, only: [ :index, :new, :create, :show ]
      resources :notification_categories
      resources :announcements
      resources :enterprise_groups do
        resources :invitations, controller: "enterprise_group_invitations", only: [ :index ] do
          member do
            post :resend
            delete :revoke
          end
        end
      end

      resources :email_change_requests, only: [ :index, :show ], param: :token do
        member do
          patch :approve
          patch :reject
        end
      end
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

      resources :organizations, only: [ :index ]
      resources :teams, only: [ :show ]
      resources :enterprise_groups, only: [ :show ]
      resources :support, only: [ :index, :show, :update ]
      resource :profile, only: [ :show, :edit, :update ], controller: "profile"
    end
  end

  # Direct User Routes
  scope "/dashboard" do
    root "users/dashboard#index", as: :user_dashboard

    namespace :users do
      resources :billing, only: [ :index, :show, :edit, :update ]
      resource :subscription, only: [ :show, :edit, :update, :destroy ]
      resources :plan_migrations, only: [ :new, :create ]
      resources :profile, only: [ :show, :edit, :update ]
      resource :settings, only: [ :show, :update ]
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
      resources :notification_categories, controller: "teams/admin/notification_categories", as: :team_admin_notification_categories

      resources :email_change_requests, controller: "teams/admin/email_change_requests", as: :team_admin_email_change_requests, only: [ :index, :show, :new, :create ], param: :token do
        member do
          patch :approve
          patch :reject
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

  # Enterprise Group Routes
  scope "/enterprise/:enterprise_group_slug" do
    root "enterprise/dashboard#index", as: :enterprise_dashboard

    resources :members, controller: "enterprise/members" do
      member do
        post :resend_invitation
        delete :revoke_invitation
      end
    end
    resources :profile, controller: "enterprise/profile", only: [ :show, :edit, :update ]
    resources :billing, controller: "enterprise/billing", only: [ :index, :show ] do
      collection do
        post :update_payment_method
        post :cancel_subscription
      end
    end
    resource :settings, controller: "enterprise/settings", only: [ :show, :update ]
    
    # Enterprise admin routes
    scope "/admin" do
      resources :notification_categories, controller: "enterprise/admin/notification_categories", as: :enterprise_admin_notification_categories
    end
  end

  # Redirect after sign in based on user type
  get "/redirect_after_sign_in", to: "redirect#after_sign_in"
end
