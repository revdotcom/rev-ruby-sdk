require 'rev-api/api_serializable'

module Rev
  # OrderRequest is used for constructing order 'spec' in consumer code and passing it into.
  # It consists of three main elements: :payment, :transcription_options and :notification.
  # You can also supply priority, reference number, and customer comment
  #
  # @note http://www.rev.com/api/ordersposttranscription, http://www.rev.com/api/ordersposttranslation, http://www.rev.com/api/orderspostcaption
  class OrderRequest < ApiSerializable
    # see {Rev::Payment}
    attr_reader :payment

    # see {Rev::TranscriptionOptions}
    attr_reader :transcription_options

    # see {Rev::TranslationOptions}
    attr_reader :translation_options
    
    # see {Rev::CaptionOptions}
    attr_reader :caption_options

    # see {Rev::Notification}
    attr_reader :notification

    # a reference number for the order meaningful for the client (optional)
    attr_reader :client_ref

    # a comment with any special messages about the order (optional)
    attr_reader :comment
    
    # a requested priority for the order, defaults to normal (optional)
    attr_reader :priority
    
    # use to correctly set priority
    PRIORITY = {
      :normal => 'Normal',
      :backlog => 'Backlog'
    }

    # @param payment [Payment] payment info
    # @param fields [Hash] of fields to initialize instance. See instance attributes for available fields.
    def initialize(payment, fields = {})
      fields = { :priority => PRIORITY[:normal] }.merge(fields)
      super fields
      @payment = payment
    end
  end

  # Payment Info. Payment can be done either by charging a credit card or by debiting the user's
  # account balance. If using a credit card, then either the user's saved credit card can be used
  # or credit card details provided.
  #
  # For credit card payments, if specifying the credit card details in the request, the required
  # elements are the card number, cardholder name, expiration month and year, and billing zipcode.
  # If using the user's saved card, you must currently specify the value "1" for the saved card id,
  # as we currently only allow a single card to be saved for a user.
  class Payment < ApiSerializable
    attr_accessor :type, :credit_card

    # use to correctly set payment type
    TYPES = {
      :credit_card => 'CreditCard',
      :account_balance => 'AccountBalance'
    }

    CC_ON_FILE_ID = 1

    # @param type [String] payment method
    # @param credit_card [CreditCard] cc obj, if type is 'CreditCard'
    def initialize(type, credit_card = nil)
      @type = type
      @credit_card = credit_card unless credit_card.nil?
    end

    class << self
      def with_credit_card_on_file()
        Payment::new(TYPES[:credit_card], CreditCard.new(:saved_id => CC_ON_FILE_ID))
      end

      def with_saved_credit_card(credit_card)
        Payment::new(TYPES[:credit_card], credit_card)
      end

      def with_account_balance()
        Payment::new(TYPES[:account_balance])
      end        
    end
  end

  # Billing address
  class BillingAddress < ApiSerializable
    attr_reader :street, :street2, :city, :state, :zip, :country_alpha2
  end

  # Credit Card
  class CreditCard < ApiSerializable
    attr_reader :number, :expiration_month, :expiration_year, :cardholder, :billing_address, :saved_id
  end

  # Superclass for the business-line options that handles capture and common validation of inputs.
  class InputOptions < ApiSerializable
    # Mandatory, contains list of inputs. Must have at least one element.
    attr_reader :inputs

    # @param inputs [Array] list of inputs
    # @param info [Hash] of fields to initialize instance.
    def initialize(inputs, info = {})
      super info
      raise(ArgumentError, "inputs must have at least one element") unless validate_inputs(inputs)
      @inputs = inputs
    end

    private
    
    def validate_inputs(inputs)
      !inputs.nil? && inputs.length > 0
    end
  end

  # Transcription options. This section contains the input media that must be transferred to our servers
  # using a POST to /inputs, and are referenced using the URIs returned by that call. We also support external links.
  # Following points explain usage of inputs:
  # - For each input, you must provide either uri or external_link, but not both. If both or neither is provided,
  #   error is returned.
  # - You should only provide an external_link if it links to page where the media can be found, rather than directly to
  #   the media file, and that we will not attempt to do anything with the link when the API call is made.
  #   This is in contrast to when you post to /inputs with a link to a media file - in that case we do download the file.
  #   So the external_link should only be used when you can't link to the media file directly.
  # - The external_link can contain anything you want, but if it's a YouTube link, we will attempt to determine the
  #   duration of the video on that page.
  # We also allow users of the api to specify if transcription should be done using our Verbatim option (:verbatim => true)
  # and to specify if Time stamps should be included (:timestamps => true).
  class TranscriptionOptions < InputOptions
    # Optional, should we transcribe the provided files verbatim? If true,
    # all filler words (i.e. umm, huh) will be included.
    attr_reader :verbatim

    # Optional, should we include timestamps?
    attr_reader :timestamps

    # @param inputs [Array] list of inputs
    # @param info [Hash] of fields to initialize instance. May contain:
    #        - :verbatim => true/false
    #        - :timestams => true/false
    def initialize(inputs, info = {})
      super inputs, info
    end
  end

  # Translation options. This section contains the input media that must be transferred to our
  # servers using a POST to /inputs, and are referenced using the URIs returned by that call.
  # For each media, word count must be specified. The language code for the source and desitination
  # languages must also be specified.
  class TranslationOptions < InputOptions
    # Mandatory, source language code
    attr_reader :source_language_code

    # Mandatory, destination language code
    attr_reader :destination_language_code

    # @param inputs [Array] list of inputs
    # @param info [Hash] of fields to initialize instance. May contain:
    #        - :source_language_code
    #        - :destination_language_code
    # @note For language codes refer to http://www.loc.gov/standards/iso639-2/php/code_list.php
    def initialize(inputs, info = {})
      super inputs, info
    end
  end
  
  # Caption options. This section contains the input media that must be transferred to our servers
  # using a POST to /inputs, and are referenced using the URIs returned by that call. We also support external links.
  # Following points explain usage of inputs:
  # - For each input, you must provide either uri or external_link, but not both. If both or neither is provided,
  #   error is returned.
  # - You should only provide an external_link if it links to page where the media can be found, rather than directly to
  #   the media file, and that we will not attempt to do anything with the link when the API call is made.
  #   This is in contrast to when you post to /inputs with a link to a media file - in that case we do download the file.
  #   So the external_link should only be used when you can't link to the media file directly.
  # - The external_link can contain anything you want, but if it's a YouTube link, we will attempt to determine the
  #   duration of the video on that page.
  # We also allow users of the api to specify the output file format(s) (:output_file_formats => Array), values
  # from OUTPUT_FILE_FORMATS.
  class CaptionOptions < InputOptions
    # Array of file formats the captions should be delivered as.  (Optional, default is SubRip)
    attr_reader :output_file_formats

    # All supported output file formats
    OUTPUT_FILE_FORMATS = {
      :subrip => 'SubRip',
      :scc => 'Scc',
      :ttml => 'Ttml',
      :qttext => 'QTtext'
    }
    
    def initialize(inputs, info = {})
      super(inputs, info)
      raise(ArgumentError, "invalid format(s)") unless validate_output_formats(info[:output_file_formats])
    end
    
    private
    
    def validate_output_formats(formats)
      formats.nil? || formats.select{|f| !OUTPUT_FILE_FORMATS.has_value?(f) }.empty?
    end
  end

  # Input for order (aka source file)
  class Input < ApiSerializable
    #  Mandatory when used with {Rev::OrderRequest::TranslationInfo}, length of document, in words
    attr_reader :word_length

    # Length of audio, in minutes (mandatory in case of inability to determine it automatically).
    # Used within {Rev::OrderRequest::TranscriptionInfo} and {Rev::OrderRequest::CaptionInfo}
    attr_reader :audio_length

    # Mandatory, URI of the media, as returned from the call to POST /inputs.
    # :external_link might substitute :uri for Transcription or Caption.
    attr_reader :uri

    # External URL, if sources wasn't POSTed as input (YouTube, Vimeo, Dropbox, etc)
    attr_reader :external_link
  end

  # Notification Info. Optionally you may request that an HTTP post be made to a url of your choice when the order enters
  # a new status (eg being transcribed or reviewed) and when it is complete.
  class Notification < ApiSerializable
    attr_reader :url, :level

    # Notification levels
    LEVELS = {
      :detailed => 'Detailed',
      :final_only => 'FinalOnly'
    }

    # @param url [String] The url for notifications. Mandatory if the notifications element is used. Updates will be posted to this URL
    # @param level [String] Optional, specifies which notifications are sent:
    #        - :detailed - a notification is sent whenever the order is in a new status or has a new comment
    #        - :final_only - (the default), notification is sent only when the order is complete
    def initialize(url, level = nil)
      @url = url
      @level = level ? level : LEVEL[:final_only]
    end
  end
end
