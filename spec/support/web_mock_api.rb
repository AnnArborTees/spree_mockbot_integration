require 'webmock'

class WebMockApi
  extend WebMock::API

  @stubs = []

  class << self
    def stub_request(*args, &block)
      stub = super(*args, &block)
      @stubs << stub
      stub
    end

    def clear!
      @stubs.each(&method(:remove_request_stub))
      @stubs = []
    end

    def stub_test_image!
      stub_request(:get, /http:\/\/test\-file\-url\.com\/test_(files)|(thumbs)\/\d+\.png/).
        to_return(status: 200, body: File.new(Rails.root.join('..', 'test_image.png').to_s))
    end
  end
end