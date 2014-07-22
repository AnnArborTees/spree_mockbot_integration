# Run Coverage report
require 'simplecov'
SimpleCov.start do
  add_filter 'spec/dummy'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Models', 'app/models'
  add_group 'Views', 'app/views'
  add_group 'Libraries', 'lib'
end

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'rspec/rails'
require 'database_cleaner'
require 'ffaker'
require 'endpoint_stub'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Requires factories defined in spree_core
require 'spree/testing_support/factories'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/url_helpers'

# Requires factories defined in lib/spree_mockbot_integration/factories.rb
require 'spree_mockbot_integration/factories'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.infer_spec_type_from_file_location!

  # == URL Helpers
  #
  # Allows access to Spree's routes in specs:
  #
  # visit spree.admin_path
  # current_path.should eql(spree.products_path)
  config.include Spree::TestingSupport::UrlHelpers
  config.include Spree::TestingSupport::ControllerRequests
  config.include Devise::TestHelpers, type: :controller

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
  config.color = true

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Capybara javascript drivers require transactional fixtures set to false, and we use DatabaseCleaner
  # to cleanup after each test instead.  Without transactional fixtures set to false the records created
  # to setup a test will be unavailable to the browser, which runs under a separate server instance.
  config.use_transactional_fixtures = false

  # Unsure why, but I appear to need to stub url helpers for the tests.
  config.before :each do
    if defined? view
      allow(view).to receive(:admin_mockbot_ideas_url).and_return "/spree/admin/mockbot/ideas"
      allow(view).to receive(:admin_mockbot_idea_url).and_return "/spree/admin/mockbot/idea"
      allow(view).to receive(:admin_mockbot_settings_url).and_return "/spree/admin/mockbot/settings"
    end
  end

  # Ensure Suite is set to use transactions for speed.
  config.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation

    # We also activate endpoint stub.
    EndpointStub.activate!
  end

  EndpointActions.mock_for_ideas config, email: 'test@test.com', token: 'AbC123'

  # Before each spec check if it is a Javascript test and switch between using database transactions or not where necessary.
  config.before :each do |example|
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start

    # Default to no stubbed authentication.
    EndpointActions.do_authentication = false
  end

  # After each spec clean the database.
  config.after :each do
    DatabaseCleaner.clean
    Endpoint::Stub.clear_all_records!
  end

  config.fail_fast = ENV['FAIL_FAST'] || false
end
