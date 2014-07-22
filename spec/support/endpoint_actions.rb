class EndpointActions
  class << self
    attr_accessor :do_authentication

    ##
    # The API::IdeasController in MockBot has some special functionality
    # that is mimicked here.
    def mock_for_ideas(config, options={})
      idea_stub = Endpoint::Stub.create_for Spree::Mockbot::Idea
      expected_email = options[:email]
      expected_token = options[:token]
      # config.before messes up the context, so we encapsulate our authenticate
      # method here.
      auth = method :authenticate

      config.before :suite do
        # Overwrite default index to add pagination headers, 
        # sort by sku, and perform searches.
        idea_stub.mock_response :get, '.json' do |request, params, stub|
          query = request.uri.query_values
          records = stub.records.dup

          # Sorta simulate SQL 'LIKE' predicate.
          records.select! { |r| 
            ['sku', 'working_name', 'product_name'].any? { |n| 
              r[n] && r[n].downcase.include?(query['search'].downcase) } } if query && query['search']

          {
            body: records.sort_by { |r| r[:sku] },
            headers: {
              'Pagination-Limit' => 100,
              'Pagination-Offset' => 0,
              'Pagination-TotalCount' => stub.records.compact.count
            }
          }
        end

        # Overwrite default find to find by sku instead of id.
        idea_stub.mock_response :get, '/:id.json' do |request, params, stub|
          { body: stub.records.find { |r| r and r[:sku] == params[:id] } }
        end

        # And add authentication
        idea_stub.override_all do |request, params, stub, &supre|
          auth.call request, expected_email, expected_token, &supre
        end
      end # config.before :suite
    end

    private
    def authenticate(request, expected_email, expected_token, &block)
      if @do_authentication
        token = request.headers['Mockbot-User-Token']
        email = request.headers['Mockbot-User-Email']
        if token && email and token == expected_token && email == expected_email
          yield
        else
          { body: '', status: 401 }
        end
      else
        yield
      end
    end
  end
end