Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  resources :credit_purchases, only: [:index, :create, :show]
  post "/webhooks/btcpay", to: "btc_pay_webhooks#create"

  # Game sessions (user-facing)
  resources :game_sessions, only: [:index, :show] do
    # Nested spot purchases under game sessions
    resources :spots, only: [:create]

    # My games collection route
    collection do
      get :my_games
    end
  end

  # Game runs (individual playable instances)
  resources :game_runs, only: [:show] do
    member do
      post :complete
    end
  end

  # Root path
  root "game_sessions#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
