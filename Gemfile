source 'https://rubygems.org'

branch = '2-2-stable'

# Provides basic authentication functionality for testing parts of your engine
gem 'spree_api', github: 'spree/spree', branch: branch
gem 'spree_backend', github: 'spree/spree', branch: branch
gem 'spree_core', github: 'spree/spree', branch: branch
gem 'spree_frontend', github: 'spree/spree', branch: branch
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: branch
gem 'spree_annarbortees_theme', github: 'annarbortees/spree_annarbortees_theme', branch: branch

group :development, :test do
  gem 'webmock'
  gem 'endpoint_stub', github: 'Resonious/endpoint_stub', branch: 'develop'
  gem 'byebug'
end

gemspec
