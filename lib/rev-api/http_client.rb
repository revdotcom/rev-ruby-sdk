module Rev

  # HTTP client handling authentication and HTTP requests at the low level for the Api class.
  # Not indended to be used directly - clients should be using the Api class instead.
  class HttpClient

    include HTTParty

    USER_AGENT = "RevOfficialRubySDK/#{VERSION}"

    # Create a new HttpClient, connecting to given host, and using the given Client and User API Keys.
    #
    # @param client_api_key [String] the client API key to use for authenticating
    # @param user_api_key [String] the user API key to use for authenticating
    # @param host [String] the host to send requests to. Should be one of Rev::Api::PRODCUTION_HOST or Rev::Api::SANDBOX_HOST
    def initialize(client_api_key, user_api_key, host)
      endpoint_uri = "https://#{host}/api/v1"
      self.class.base_uri(endpoint_uri)

      auth_string = "Rev #{client_api_key}:#{user_api_key}"
      @default_headers = {
        'Authorization' => auth_string,
        'User-Agent' => USER_AGENT # to track usage of SDK
      }
    end

    # Performs HTTP GET of JSON data.
    #
    # @param operation [String] URL suffix describing specific operation, like '/orders'
    # @param headers [Hash] hash of headers to use for the request
    # @return [HTTParty::Response] response
    def get(operation, headers = {})
      headers = @default_headers.merge(headers)
      self.class.get(operation, :headers => headers)
    end

    # Performs HTTP GET of binary data. Note, unlike post, this returns a
    # Net::HTTP::Response, not HTTParty::Response.
    #
    # If this method is passed a block, will pass response to that block. in that case the response is not yet
    # read into memory, so the block can read it progressively. otherwise, returns the response.
    #
    # @param operation [String] URL suffix describing specific operation, like '/orders'
    # @param headers [Hash] hash of headers to use for the request
    # @yieldparam resp [Net::HTTP::Response] the response, ready to be read
    # @return [Net::HTTP::Response] response
    def get_binary(operation, headers = {}, &block)
      uri = URI.parse("#{self.class.base_uri}#{operation}")
      headers = @default_headers.merge(headers)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      get = Net::HTTP::Get.new(uri.request_uri, headers)
      if block_given?
        http.request(get) do |resp|
          yield resp
        end
      else
        http.request(get)
      end
    end

    # Performs HTTP POST of JSON data.
    #
    # @param operation[String] URL suffix describing specific operation
    # @param data [Hash] hash of keys/values to post in request body
    # @param headers [Hash] hash of headers to use for the request
    # @return [HTTParty::Response] response
    def post(operation, data = {}, headers = {})
      headers = @default_headers.merge(headers)
      self.class.post(operation, :headers => headers, :body => data)
    end


    # Performs HTTP POST of binary data. Note, unlike post, this returns a
    # Net::HTTP::Response, not HTTParty::Response.
    #
    # @param operation[String] URL suffix describing specific operation
    # @param file [File] file-like object containing the data to post
    # @param headers [Hash] hash of headers to use for the request
    # @return [Net::HTTP::Response] response
    def post_binary(operation, file, headers = {})
      uri = URI.parse("#{self.class.base_uri}#{operation}")
      headers = @default_headers.merge(headers)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      post = Net::HTTP::Post.new(uri.request_uri, headers)
      post["Content-Length"] = file.stat.size.to_s
      post.body_stream = file

      response = http.request(post)
    end
  end
end
