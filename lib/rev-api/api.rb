require 'rev-api/version'
require 'rev-api/http_client'
require 'rev-api/exceptions'
require 'json'

# automatically include business logic objects
Dir[File.dirname(__FILE__) + '/models/*.rb'].each do |file|
  require file
end

# Rev API Ruby SDK
module Rev
  # Main point of interaction with API.
  # Wraps common REST operations, returning plain objects.
  # Internally utilizes JSON resource representation.
  class Api

    # Production host. Used by default for new Rev::Api client
    PRODUCTION_HOST = 'www.rev.com'

    # Sandbox domain - pass 'Rev::Api::SANDBOX_HOST' as third param
    # into Rev::Api ctor
    SANDBOX_HOST = 'api-sandbox.rev.com'

    # @note https://www.rev.com/api/security
    # @param client_api_key [String] secret key specific to each partner that wishes to use the Rev API
    # @param user_api_key [String] secret key specific to a Rev user, which identifies the user account under whose privileges the requested operation executes
    # @param host [String] use {Rev::Api::PRODUCTION_HOST} or {Rev::Api::SANDBOX_HOST}. Production is default value
    # @return [HttpClient] client obj
    def initialize(client_api_key, user_api_key, host = PRODUCTION_HOST)
      @client = HttpClient.new(client_api_key, user_api_key, host)
    end

    # Loads single page of existing orders for current client
    #
    # @note https://www.rev.com/api/ordersget
    # @param page [Int, nil] 0-based page number, defaults to 0
    # @return [OrdersListPage] paged result containing 'orders'
    def get_orders_page(page = 0)
      response = @client.get("/orders?page=#{page.to_i}")
      Api.verify_get_response(response)
      OrdersListPage.new(Api.parse(response))
    end

    # Loads all orders for current client. Works by calling get_orders_page multiple times.
    # Use with caution if your order list might be large.
    #
    # @note https://www.rev.com/api/ordersget
    # @return [Array of Order] list of orders
    def get_all_orders
      orders = []
      page = 0
      loop do
        orders_page = self.get_orders_page page
        page += 1
        orders.push *orders_page.orders
        break if (page * orders_page.results_per_page >= orders_page.total_count)
      end
      orders
    end

    # Loads orders whose associated reference ID is the given client_ref
    #
    # @note https://www.rev.com/api/ordersget
    # @param client_ref [String, nil] client reference (required)
    # @param page [Int, nil] 0-based page number, defaults to 0
    # @return [OrdersListPage] paged result containing 'orders' list
    # @raise [ArgumentError] client_ref is nil
    def get_orders_by_client_ref(client_ref, page = 0)
      raise ArgumentError if client_ref.nil?

      response = @client.get("/orders?clientRef=#{URI.escape(client_ref)}&page=#{page.to_i}")
      Api.verify_get_response(response)
      OrdersListPage.new(Api.parse(response))
    end

    # Returns Order given an order number.
    #
    # @note https://www.rev.com/api/ordersgetone
    # @param number [String] order number, like 'TCXXXXXXXX'
    # @return [Order] order obj
    def get_order(number)
      response = @client.get("/orders/#{number}")
      Api.verify_get_response(response)
      Order.new(Api.parse(response))
    end

    # Cancel an order by number. If cancellation is not allowed, Rev::Api::BadRequestError is raised.
    #
    # @note https://www.rev.com/api/orderscancel
    # @param number [String] order number
    # @return [Boolean] true on success, raised Exception from Rev::Api namespace otherwise
    def cancel_order(number)
      data = { :order_num => number }
      response = @client.post("/orders/#{number}/cancel", data)
      Api.verify_post_response(response)
    end

    # Get metadata about an order attachment.
    # Use this method to retrieve information about an order attachment (either transcript,
    # translation, or source file).
    #
    # @note https://www.rev.com/api/attachmentsget
    # @param id [String] attachment id, as returned in info about an order
    # @return [Attachment] attachment object
    def get_attachment_metadata(id)
      response = @client.get("/attachments/#{id}")
      Api.verify_get_response(response)
      Attachment.new(Api.parse(response))
    end

    # Get the raw data for the attachment with given id.
    # Download the contents of an attachment. Use this method to download either a finished transcript,
    # finished translation or a source file for an order.
    # For transcript and translation attachments, you may request to get the contents in a specific
    # representation, specified via a mime-type.
    #
    # See {Rev::Order::Attachment::REPRESENTATIONS} hash, which contains symbols for currently supported mime types.
    # The authoritative list is in the API documentation at https://www.rev.com/api/attachmentsgetcontent
    #
    # If a block is given, the response is passed to the block directly, to allow progressive reading of the data.
    # In this case, the block must itself check for error responses, using Api.verify_get_response.
    # If no block is given, the full response is returned. In that case, if the response is an error, an appropriate
    # error is raised.
    #
    # @param id [String] attachment id
    # @param mime_type [String, nil] mime-type for the desired format in which the content should be retrieved.
    # @yieldparam resp [Net::HTTP::Response] the response, ready to be read
    # @return [Net::HTTP::Response] the response containing raw data
    def get_attachment_content(id, mime_type = nil, &block)
      headers = {}

      unless mime_type.nil?
        headers['Accept'] = mime_type
        headers['Accept-Charset'] = 'utf-8' if mime_type.start_with? 'text/'
      end

      if block_given?
        @client.get_binary("/attachments/#{id}/content", headers, &block)
      else
        response = @client.get_binary("/attachments/#{id}/content", headers)
        Api.verify_get_response(response)
        response
      end
    end

    # Get the raw data for the attachment with given id.
    # Download the contents of an attachment and save it into a file. Use this method to download either a finished transcript,
    # finished translation or a source file for an order.
    # For transcript and translation attachments, you may request to get the contents in a specific
    # representation, specified via a mime-type.
    #
    # See {Rev::Order::Attachment::REPRESENTATIONS} hash, which contains symbols for currently supported mime types.
    # The authoritative list is in the API documentation at https://www.rev.com/api/attachmentsgetcontent
    #
    # @param id [String] attachment id
    # @param path [String, nil] path to file into which the content is to be saved.
    # @param mime_type [String, nil] mime-type for the desired format in which the content should be retrieved.
    # @return [String] filepath content has been saved to. Might raise standard IO exception if file creation files
    def save_attachment_content(id, path, mime_type = nil)
      headers = {}

      unless mime_type.nil?
        headers['Accept'] = mime_type
        headers['Accept-Charset'] = 'utf-8' if mime_type.start_with? 'text/'
      end

      # same simple approach as box-api does for now: return response.body as-is if path for saving is nil
      File.open(path, 'wb') do |file|
        response = @client.get_binary("/attachments/#{id}/content", headers) do |resp|
          resp.read_body do |segment|
            file.write(segment)
          end
        end
        Api.verify_get_response(response)
      end

      # we don't handle IO-related exceptions
      path
    end

    # Get the content of the attachment with given id as a string. Use this method to grab the contents of a finished transcript
    # or translation as a string. This method should generally not be used for source attachments, as those are typically
    # binary files like MP3s, which cannot be converted to a string.
    #
    # May raise Rev::Api::NotAcceptableError if the attachment cannot be converted into a text representation.
    #
    # @param id [String] attachment id
    # @return [String] the content of the attachment as a string
    def get_attachment_content_as_string(id)
      response = self.get_attachment_content(id, Attachment::REPRESENTATIONS[:txt])
      response.body
    end

    # Submit a new order using {Rev::OrderRequest}.
    # @note https://www.rev.com/api/ordersposttranscription - for full information
    #
    # @param order_request [OrderRequest] object specifying payment, inputs, options and notification info.
    #        inputs must previously be uploaded using upload_input or create_input_from_link
    # @return [String] order number for the new order
    #         Raises {Rev::BadRequestError} on failure (.code attr exposes API error code -
    #         see {Rev::OrderRequestError}).
    def submit_order(order_request)
      response = @client.post("/orders", order_request.to_json, { 'Content-Type' => 'application/json' })
      Api.verify_post_response(response)

      new_order_uri = response.headers['Location']
      return new_order_uri.split('/')[-1]
    end

    # Upload given local file directly as source input for order.
    # @note https://www.rev.com/api/inputspost
    #
    # @param path [String] mandatory, path to local file (relative or absolute) to upload
    # @param content_type [String] mandatory, content-type of the file you're uploading
    # @return [String] URI identifying newly uploaded media. This URI can be used to identify the input
    #         when constructing a OrderRequest object to submit an order.
    #         {Rev::BadRequestError} is raised on failure (.code attr exposes API error code -
    #         see {Rev::InputRequestError}).
    def upload_input(path, content_type)
      filename = Pathname.new(path).basename
      headers = {
        'Content-Disposition' => "attachment; filename=\"#{filename}\"",
        'Content-Type' => content_type
      }

      File.open(path) do |data|
        response = @client.post_binary("/inputs", data, headers)
        Api.verify_post_response(response)

        headers = HTTParty::Response::Headers.new(response.to_hash)
        return headers['Location']
      end
    end

    # Request creation of a source input based on an external URL which the server will attempt to download.
    # @note https://www.rev.com/api/inputspost
    #
    # @param url [String] mandatory, URL where the media can be retrieved. Must be publicly accessible.
    #        HTTPS urls are ok as long as the site in question has a valid certificate
    # @param filename [String, nil] optional, the filename for the media. If not specified, we will
    #        determine it from the URL
    # @param content_type [String, nil] optional, the content type of the media to be retrieved.
    #        If not specified, we will try to determine it from the server response
    # @return [String] URI identifying newly uploaded media. This URI can be used to identify the input
    #         when constructing a OrderRequest object to submit an order.
    #         {Rev::BadRequestError} is raised on failure (.code attr exposes API error code -
    #         see {Rev::InputRequestError}).
    def create_input_from_link(url, filename = nil, content_type = nil)
      request = { :url => url }
      request[:filename] = filename unless filename.nil?
      request[:content_type] = content_type unless content_type.nil?

      response = @client.post("/inputs", request.to_json, { 'Content-Type' => 'application/json' })
      Api.verify_post_response(response)

      response.headers['Location']
    end

  private
    # Below are utility helper methods for handling response
    class << self

      # Parse given response's body JSON into Hash, so that it might be
      # easily mapped onto business logic object.
      #
      # @param response [Response] HTTParty response obj
      # @return [Hash] hash of values parsed from JSON
      def parse(response)
        JSON.load response.body.to_s
      end

      # Raises exception if response is not considered as success
      #
      # @param response [HTTPParty::Response] HTTParty response obj. Net::HTTPResponse represented by .response
      # @return [Boolean] true if response is considered as successful
      def verify_get_response(response)
        # HTTP response codes are handled here and propagated up to the caller, since caller should be able
        # to handle all types of errors the same - using exceptions
        unless response.response.instance_of? Net::HTTPOK
          Api.handle_error(response)
        end

        true
      end

      # (see #verify_get_response)
      def verify_post_response(response)
        # see https://www.rev.com/api/errorhandling
        unless response.response.instance_of?(Net::HTTPCreated) || response.response.instance_of?(Net::HTTPNoContent)
          Api.handle_error(response)
        end

        true
      end

      # Given a response, raises a corresponding Exception.
      # Full response is given for the sake of BadRequest reporting,
      # which usually contains validation errors.
      #
      # @param response [Response] containing failing status to look for
      def handle_error(response)
        case response.response
          when Net::HTTPBadRequest
            # Bad request - response contains error code and details. Usually means failed validation
            body = JSON.load response.body.to_s
            msg = "API responded with code #{body['code']}: #{body['message']}"
            msg += " Details: #{body['detail'].to_s}" if body['detail']
            raise BadRequestError.new msg, body['code']
          when Net::HTTPUnauthorized
            raise NotAuthorizedError
          when Net::HTTPForbidden
            raise ForbiddenError
          when Net::HTTPNotFound
            raise NotFoundError
          when Net::HTTPNotAcceptable
            raise NotAcceptableError
          when Net::HTTPServerError
            raise ServerError, "Status code: #{response.code}"
          else
            raise UnknownError
        end
      end
    end
  end
end
