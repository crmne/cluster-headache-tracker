Rails.application.routes.draw do
  # resources :headache_logs
  devise_for :users, controllers: { sessions: "users/sessions" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  get "home/index"
  root "home#index"

  # Shared Logs
  get "shared_logs/:token", to: "shared_logs#index", as: :shared_logs

  # Generate Share Link
  post "generate_share_link", to: "headache_logs#generate_share_link"

  # Charts
  get "charts/index"
  get "charts", to: "charts#index"

  resources :headache_logs do
    collection do
      get :export
      post :import
    end
  end
end
