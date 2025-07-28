Rails.application.routes.draw do
  # resources :headache_logs
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "browserconfig" => "rails/pwa#browserconfig", as: :pwa_browserconfig, defaults: { format: :xml }

  # Defines the root path route ("/")
  get "home/index"
  root "home#index"

  # Hotwire Native navigation helpers
  get "/recede_historical_location", to: "application#recede_historical_location"

  get "faq", to: "home#faq", as: :faq
  get "imprint", to: "home#imprint", as: :imprint
  get "privacy-policy", to: "home#privacy_policy", as: :privacy_policy
  get "neurologist", to: "home#neurologist", as: :neurologist

  # Shared Logs
  get "shared_logs/:token", to: "shared_logs#index", as: :shared_logs

  # Share Link
  post "generate_share_link", to: "headache_logs#generate_share_link"
  delete "expire_share_link", to: "headache_logs#expire_share_link"

  # Charts
  get "charts/index"
  get "charts", to: "charts#index"

  resources :headache_logs do
    collection do
      get :export
      post :import
      get :print
    end
  end

  resource :settings, only: [ :show ], controller: "users/settings" do
    patch :update_username
    patch :update_password
    post :changelog_acknowledged
    post :welcome_acknowledged
  end

  resource :feedback, only: [ :show, :new, :create ], controller: "feedback" do
    get :thank_you
  end

  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"

    resources :users, only: [ :index, :destroy ] do
      member do
        post :reset_password
        post :reset_changelog
        post :reset_welcome
      end

      collection do
        post :reset_all_changelogs
        post :reset_all_welcomes
      end
    end

    resources :feedback_surveys, only: [ :index, :show, :destroy ] do
      collection do
        post :import
        delete :destroy_all
      end
    end
  end
end
