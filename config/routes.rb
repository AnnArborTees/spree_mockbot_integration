Spree::Core::Engine.routes.draw do
  namespace :admin do
    namespace :mockbot do
      resources :ideas do
        post '/publish', to: 'ideas#publish', as: :publish
      end
    end
    get '/api_settings', to: 'api_settings#edit', as: :api_settings
    put '/api_settings', to: 'api_settings#update'
    get '/api_settings/:id', to: 'api_settings#defaults', as: :default_api_settings
  end
end
