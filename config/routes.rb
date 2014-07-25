Spree::Core::Engine.routes.draw do
  namespace :admin do
    namespace :mockbot do
      resources :ideas do
        post '/publish', to: 'ideas#publish', as: :publish
      end
    end
    get '/api_settings', to: 'api_settings#edit', as: :api_settings
    put '/api_settings', to: 'api_settings#update'
    post '/api_settings', to: 'api_settings#reset'
  end
end
