Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :events, except: :destroy do
    resource :rsvp, only: %i[ create destroy ]
    resources :comments, only: %i[ create destroy ]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  mount PlanDriven::Wizard::Engine, at: "/plan_driven" if Rails.env.development?

  root "events#index"
end
