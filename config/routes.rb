Spree::Core::Engine.routes.draw do
  namespace :admin do
    namespace :mockbot do
      resources :ideas
    end
  end
end
