module EndpointActions
  ##
  # The API::IdeasController in MockBot has some special functionality
  # that is mimicked here.
  def self.mock_for_ideas(stub)
    # Overwrite default index to add pagination headers, 
    # sort by sku, and perform searches.
    stub.mock_response :get, '.json' do |request, params, stub|
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
    stub.mock_response :get, '/:id.json' do |request, params, stub|
      { body: stub.records.find { |r| r and r.sku == params[:id] } }
    end
  end
end