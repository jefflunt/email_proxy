Rails.application.routes.draw do
  defaults format: :json do
    post '/email', to: 'emails#create'
  end
end
