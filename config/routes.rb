Spree::Core::Engine.routes.draw do
  namespace :admin do
    namespace :mockbot do
      resources :ideas do
        resources :publishers, shallow: true, except: [:new]
      end
    end
    get 'mockbot/ideas/:idea_id/publish', to: 'mockbot/publishers#new', as: :new_idea_publisher
    # TODO make this clump into resources
    get '/api_settings', to: 'api_settings#edit', as: :api_settings
    put '/api_settings', to: 'api_settings#update'
    get '/api_settings/:id', to: 'api_settings#defaults', as: :default_api_settings
  end
end
