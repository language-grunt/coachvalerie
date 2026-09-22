Rails.application.routes.draw do
  root "hello#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
