Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "preview-health/database" => "hello#index"
  root "replica#show"
  get "*path", to: "replica#show", format: false
end
