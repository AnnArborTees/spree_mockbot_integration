require 'spree_mockbot_integration/quick_curry'

class EndpointActions
  extend SpreeMockbotIntegration::QuickCurry
  class << self
    attr_accessor :do_authentication

    def mock_for_ideas(config, options={})
      idea_stub = Endpoint::Stub[Spree::Mockbot::Idea]
      expected_email = options[:email]
      expected_token = options[:token]

      auth = curry(:authenticate).('Mockbot', expected_email, expected_token)

      idea_stub.mock_response(:get, '.json', &method(:idea_index))
      idea_stub.override_response(:get, '/:id.json', &method(:idea_show))
      idea_stub.override_all(&to_authenticate_with(auth))
    end

    def mock_for_sizes(config, options={})
      size_stub = Endpoint::Stub[Spree::Crm::Size]
      expected_email = options[:email]
      expected_token = options[:token]

      auth = curry(:authenticate).('Crm', expected_email, expected_token)

      size_stub.override_response(:get, '.json', &method(:size_index))
      size_stub.override_all(&to_authenticate_with(auth))
    end

    def mock_for_colors(config, options={})
      color_stub = Endpoint::Stub[Spree::Crm::Color]

      expected_email = options[:email]
      expected_token = options[:token]
      
      auth = curry(:authenticate).('Crm', expected_email, expected_token)

      color_stub.override_all(&to_authenticate_with(auth))
    end

    def mock_for_imprintables(config, options={})
      imprintable_stub = Endpoint::Stub[Spree::Crm::Imprintable]

      expected_email = options[:email]
      expected_token = options[:token]
      
      auth = curry(:authenticate).('Crm', expected_email, expected_token)

      imprintable_stub.override_all(&to_authenticate_with(auth))
    end

    protected

    def idea_index(request, params, stub)
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

    def idea_show(request, params, stub, &supr)
      id = stub.records.find_index { |r| r && r['sku'] == params[:id] }
      raise "No idea with sku #{params[:id]} found" if id.nil?
      supr.call request, { id: id }, stub
    end

    def size_index(request, params, stub, &supr)
      query = request.uri.query_values
      if query['color'] && query['imprintable']
        # The idea at this point would be to find the imprintable variants that corrospond to
        # the given imprintable + color.
        {
          body: if query['imprintable'] == "Unisex"
            if query['color'] == 'Blue'
              [
                { id: 3, name: 'Large', sku: '03', display_value: 'L' },
                { id: 4, name: 'Extra Large', sku: '04', display_value: 'XL' }
              ]
            else
              [
                { id: 1, name: 'Small', sku: '77', display_value: 'S' },
                { id: 2, name: 'Medium', sku: '44', display_value: 'M' }
              ]
            end
          else
            [
              { id: 2, name: 'Medium', sku: '44', display_value: 'M' },
              { id: 3, name: 'Large', sku: '03', display_value: 'L' }
            ]
          end
        }
      else
        supr.call
      end
    end

    def to_authenticate_with(auth)
      proc do |request, params, stub, &supr|
        auth.call(request, &supr)
      end
    end

    def authenticate(prefix, expected_email, expected_token, request, &block)
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