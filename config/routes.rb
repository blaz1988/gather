Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :events, except: :destroy do
    resource :rsvp, only: %i[ create destroy ]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
end
