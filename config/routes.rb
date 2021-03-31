Rails.application.routes.draw do
  defaults format: :json do
    resources :emails, only: :create
  end
end
