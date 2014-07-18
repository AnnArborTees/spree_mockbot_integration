module EndpointActions
  def self.paginated_index(stub)
    stub.mock_response :get, '.json' do |request, params, stub|
      {
        body: stub.records,
        headers: {
          'Pagination-Limit' => 100,
          'Pagination-Offset' => 0,
          'Pagination-TotalCount' => stub.records.compact.count
        }
      }
    end
  end
end