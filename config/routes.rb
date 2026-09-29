Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :events, except: :destroy

  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
end
