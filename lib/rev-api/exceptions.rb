module Rev
  class ApiError < StandardError; end

  # 400 BadRequest. Response body contains API error code and optional details
  class BadRequestError < ApiError

    # Code of the validation error
    attr_reader :code

    # @param message [String] custom message, usually includes API validation error code and it's meaning
    # @param code [Integer] API validation code is passed separately to be evaluated in consumer's app
    def initialize(message, code)
      super message
      @code = code
    end
  end

  # 401 Unauthorized
  class NotAuthorizedError < ApiError; end

  # 403 Forbidden (not allowed)
  class ForbiddenError < ApiError; end

  # 404 Not Found
  class NotFoundError < ApiError; end

  # 406 NotAcceptable (used when requested representation is not supported by attachment)
  class NotAcceptableError < ApiError; end

  # 500 ServerError (internal error on API server)
  class ServerError < ApiError; end

  # have no idea what's going on - used in 'pokemon' rescue
  class UnknownError < ApiError; end

  # Constants for validation error codes in OrderRequest response
  module OrderRequestErrorCodes
    # 10001 Missing Inputs - if the order request did not contain any input media
    MISSING_INPUTS = 10001

    # 10002 Invalid Input - if one of the input media URIs is invalid, eg does not identify a valid media uploaded via a POST to /inputs
    INVALID_INPUTS = 10002

    # 10003 Multiple options specified - only options for one service can be included per each order placement request
    MULTIPLE_OPTIONS_SPECIFIED = 10003

    # 10001 Missing Inputs - if the order request did not contain any input media
    OPTIONS_NOT_SPECIFIED = 10004

    # 10005 External Link and URI specified - only External Link or URI should be set for input media
    EXTERNAL_LINK_AND_URI_SPECIFIED = 10005

    # 10006 Input Location is not specified - neither of External Link and URI set for input media
    EXTERNAL_LINK_OR_URI_NOT_SPECIFIED = 10006

    # 20001 Invalid Media Length - If one of the input medias has a specified length that is not a positive integer
    INVALID_MEDIA_LENGTH = 20001

    # @deprecated Use {#OrderRequestErrorCodes.INVALID_MEDIA_LENGTH} instead
    INVALID_AUDIO_LENGTH = INVALID_MEDIA_LENGTH

    # 20003 Invalid Language Code - the language codes provided for subtitles are invalid
    INVALID_LANGUAGE_CODE = 20003

    # 20010 Reference Number Too Long Code - the reference number provided longer than 40 characters
    REFERENCE_NUMBER_TOO_LONG = 20010

    # 30001 Missing Payment Info - if the order request did not contain a payment information element
    MISSING_PAYMENT_INFO = 30001

    # 30002 Missing Payment Type - if the order request did not contain a payment kind element
    MISSING_PAYMENT_TYPE = 30002

    # 30010 Ineligible For Balance Payments - if the user on whose behalf the order request was made is not eligible for paying using account balance
    INELIGIBLE_FOR_BALANCE_PAYMENT = 30010

    # 30011 Account Balance Limit Exceeded - if the order request specified payment using account balance, but doing so would exceed the user's balance limit
    ACCOUNT_BALANCE_LIMIT_EXCEEDED = 30011

  end

  module InputRequestErrorCodes
    # 10001 Unsupported Content Type – if the content type of the media is not currently supported by our system.
    # Supported media types for inputs are listed in https://www.rev.com/api/inputspost
    UNSUPPORTED_CONTENT_TYPE = 10001

    # 10002 Could not retrieve file – if we could not retrieve the file from the specified location.
    COULD_NOT_RETRIEVE_MEDIA = 10002

    # 10003 Invalid multipart request – If the multipart request did not contain exactly one file part, or was otherwise malformed.
    INVALID_MULTIPART_REQUEST = 10003

    # 10004 Unspecified filename - If the filename for the media was not specified explicitly and could not be determined automatically.
    UNSPECIFIED_FILENAME = 10004
  end

end
