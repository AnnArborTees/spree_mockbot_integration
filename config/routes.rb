Spree::Core::Engine.routes.draw do
  namespace :admin do
    namespace :mockbot do
      resources :ideas do
        post '/publish', to: 'ideas#publish', as: :publish
      end
      get '/settings', to: 'settings#edit', as: :settings
      put '/settings', to: 'settings#update'
      post '/settings', to: 'settings#reset'
    end
  end
end
