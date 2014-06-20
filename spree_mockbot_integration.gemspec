# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_mockbot_integration'
  s.version     = '2.2.0'
  s.summary     = 'Spree Mockbot Integration'
  s.description = 'Link up MockBot product publisher with Ann Arbor Tees Store'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Ricky Winowiecki'
  s.email     = 'ricky@annarbortees.com'
  s.homepage  = 'http://www.annarbortees.com'

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 2.2.0'

  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'activeresource'
  s.add_development_dependency 'figaro'
end
