source 'https://rubygems.org'

branch = '2-2-stable'

# Provides basic authentication functionality for testing parts of your engine
gem 'sunspot_rails'
gem 'sunspot_solr'
gem 'spree_api', github: 'spree/spree', branch: branch
gem 'spree_backend', github: 'spree/spree', branch: branch
gem 'spree_core', github: 'spree/spree', branch: branch
gem 'spree_frontend', github: 'spree/spree', branch: branch
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: branch
gem 'spree_annarbortees_theme', github: 'annarbortees/spree_annarbortees_theme', branch: branch
gem 'spree_multi_domain', github: 'annarbortees/spree-multi-domain', branch: branch

group :development, :test do
  gem 'webmock'
  gem 'endpoint_stub', github: 'Resonious/endpoint_stub', branch: 'develop'
  gem 'byebug', platforms: :mri
  gem 'rubinius-debugger', platforms: :rbx
end

gemspec
