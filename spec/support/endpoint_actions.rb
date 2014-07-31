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
      auth = method(:authenticate).to_proc.curry['Mockbot']

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
            body: records.sort_by { |r| r && r[:sku] },
            headers: {
              'Pagination-Limit' => 100,
              'Pagination-Offset' => 0,
              'Pagination-TotalCount' => stub.records.compact.count
            }
          }
        end

        # Overwrite default find to find by sku instead of id.
        idea_stub.override_response :get, '/:id.json' do |request, params, stub, &rsuper|
          id = stub.records.find_index { |r| r and r[:sku] == params[:id] }
          params[:id] = id
          rsuper.call request, {id: id}
        end

        # Update also...
        idea_stub.override_response :put, '/:id.json' do |request, params, stub, &rsuper|
          id = stub.records.find_index { |r| r and r[:sku] == params[:id] }
          params[:id] = id
          rsuper.call request, {id: id}
        end

        # And add authentication
        idea_stub.override_all do |request, params, stub, &rsuper|
          auth.call request, expected_email, expected_token, &rsuper
        end
      end # config.before :suite
    end

    def mock_for_sizes(config, options={})
      size_stub = Endpoint::Stub.create_for Spree::Crm::Size
      expected_email = options[:email]
      expected_token = options[:token]
      # config.before messes up the context, so we encapsulate our authenticate
      # method here.
      auth = method(:authenticate).to_proc.curry['Crm']

      config.before :suite do

        # Stub size queries
        size_stub.override_response :get, '.json' do |request, params, stub, &supr|
          query = request.uri.query_values
          if query['color'] and query['imprintable']
            # The idea at this point would be to find the imprintable variants that corrospond to
            # the given imprintable + color.
            {
              body: if query['imprintable'] == "Gildan 5000"
                if query['color'] == 'Blue'
                  [{ id: 3, name: 'Large', sku: '03' }, { id: 4, name: 'Extra Large', sku: '04' }]
                else
                  [{ id: 1, name: 'Small', sku: '01' }, { id: 2, name: 'Medium', sku: '02' }]
                end
              else
                [{ id: 2, name: 'Medium', sku: '02' }, { id: 3, name: 'Large', sku: '03' }]
              end
            }
          elsif query['find']
            response = supr.call
            response[:body] = response[:body].select { |r| r['name'].downcase == query['find'].downcase }
            response
          else
            supr.call
          end
        end

        size_stub.override_all do |request, params, stub, &rsuper|
          auth.call request, expected_email, expected_token, &rsuper
        end

      end # config.before :suite
    end

    def mock_for_colors(config, options={})
      color_stub = Endpoint::Stub.create_for Spree::Crm::Color

      expected_email = options[:email]
      expected_token = options[:token]
      # config.before messes up the context, so we encapsulate our authenticate
      # method here.
      auth = method(:authenticate).to_proc.curry['Crm']

      config.before :suite do

        # Allow us to grab colors by name
        color_stub.override_response :get, '.json' do |request, params, stub, &supr|
          query = request.uri.query_values
          if query['find']
            response = supr.call
            response[:body] = response[:body].select { |r| r['name'].downcase == query['find'].downcase }
            response
          else
            supr.call
          end
        end

        color_stub.override_all do |request, params, stub, &rsuper|
          auth.call request, expected_email, expected_token, &rsuper
        end

      end
    end

    def mock_for_imprintables(config, options={})
      imprintable_stub = Endpoint::Stub.create_for Spree::Crm::Imprintable

      expected_email = options[:email]
      expected_token = options[:token]
      # config.before messes up the context, so we encapsulate our authenticate
      # method here.
      auth = method(:authenticate).to_proc.curry['Crm']

      config.before :suite do

        # Allow us to grab imprintables by name ( TODO change from name to whatever else )
        imprintable_stub.override_response :get, '.json' do |request, params, stub, &supr|
          query = request.uri.query_values
          if query['find']
            response = supr.call
            response[:body] = response[:body].select { |r| r['style_name'].downcase == query['find'].downcase }
            response
          else
            supr.call
          end
        end

        imprintable_stub.override_all do |request, params, stub, &rsuper|
          auth.call request, expected_email, expected_token, &rsuper
        end

      end
    end

    private

    def authenticate(prefix, request, expected_email, expected_token, &block)
      if @do_authentication
        token = request.headers["#{prefix}-User-Token"]
        email = request.headers["#{prefix}-User-Email"]
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