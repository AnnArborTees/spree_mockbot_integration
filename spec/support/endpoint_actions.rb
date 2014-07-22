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
      # config.before context is ducked up and our defined methods aren't available.
      authenticate = method(:authenticate)

      config.before :suite do
        # Overwrite default index to add pagination headers, 
        # sort by sku, and perform searches.
        idea_stub.mock_response :get, '.json' do |request, params, stub|
          query = request.uri.query_values
          records = stub.records.dup

          authenticate.call(request, expected_email, expected_token) do
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
        end

        # Overwrite default find to find by sku instead of id.
        idea_stub.mock_response :get, '/:id.json' do |request, params, stub|
          authenticate.call(request, expected_email, expected_token) do
            { body: stub.records.find { |r| r and r[:sku] == params[:id] } }
          end
        end
      end # before :suite
    end

    private
    def authenticate(request, expected_email, expected_token, &block)
      if @do_authentication
        token = request.headers['Mockbot-User-Token']
        email = request.headers['Mockbot-User-Email']
        puts "sent token: #{token} sent email: #{email}"
        puts "expected token: #{expected_token} expected email: #{expected_email}"
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