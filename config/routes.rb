Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :mockbot_ideas
  end
end
