require 'rev-api/api_serializable'

module Rev
  # OrderRequest is used for constructing order 'spec' in consumer code and passing it into.
  # It consists of three main elements: :payment, :transcription_options and :notification.
  # You can also supply reference number, customer comment, and whether standard turnaround time is not required
  #
  # @note https://www.rev.com/api/ordersposttranscription, https://www.rev.com/api/ordersposttranslation, https://www.rev.com/api/orderspostcaption
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

    # a boolean flag specifying whether normal turnaround time is not required, defaults to false (optional)
    attr_reader :non_standard_tat_guarantee

    # @param payment [Payment] payment info
    # @param fields [Hash] of fields to initialize instance. See instance attributes for available fields.
    # @deprecated payment always defaults to :account_balance
    def self.new_with_payment(payment, fields = {})
      fields = { :non_standard_tat_guarantee => false }.merge(fields)
      super fields
      @payment = payment
    end

    # @param fields [Hash] of fields to initialize instance. See instance attributes for available fields.
    def initialize(fields = {})
      fields = { :non_standard_tat_guarantee => false }.merge(fields)
      @payment = Rev::Payment.with_account_balance
      super fields
    end
  end

  # Payment Info. Payment can only be done by debiting the user's account balance.
  # @deprecated setting the payment is no longer necessary. All orders now default to :account_balance
  class Payment < ApiSerializable
    attr_accessor :type

    # use to correctly set payment type
    TYPES = {
      :account_balance => 'AccountBalance'
    }

    CC_ON_FILE_ID = 1

    # @param type [String] payment method
    def initialize(type)
      @type = type
    end

    class << self
      def with_account_balance()
        Payment::new(TYPES[:account_balance])
      end
    end
  end

  # Billing address
  class BillingAddress < ApiSerializable
    attr_reader :street, :street2, :city, :state, :zip, :country_alpha2
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
  # @see https://www.rev.com/api/ordersposttranscription
  class TranscriptionOptions < InputOptions
    # Optional, should we transcribe the provided files verbatim? If true,
    # all filler words (i.e. umm, huh) will be included.
    attr_reader :verbatim

    # Optional, should we include timestamps?
    attr_reader :timestamps

    # @param inputs [Array] list of inputs
    # @param info [Hash] of fields to initialize instance. May contain:
    #        - :verbatim => true/false
    #        - :timestamps => true/false
    def initialize(inputs, info = {})
      super inputs, info
    end
  end

  # Translation options. This section contains the input media that must be transferred to our
  # servers using a POST to /inputs, and are referenced using the URIs returned by that call.
  # For each media, word count must be specified. The language code for the source and desitination
  # languages must also be specified.
  # @see https://www.rev.com/api/ordersposttranslation
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
  # @see https://www.rev.com/api/orderspostcaption
  class CaptionOptions < InputOptions
    # Array of file formats the captions should be delivered as.  (Optional, default is SubRip)
    attr_reader :output_file_formats

    # Optional, Array of language codes to request foreign language subtitles
    attr_reader :subtitle_languages

    # All supported output file formats
    OUTPUT_FILE_FORMATS = {
      :subrip => 'SubRip',
      :scc => 'Scc',
      :mcc => 'Mcc',
      :ttml => 'Ttml',
      :qttext => 'QTtext',
      :transcript => 'Transcript',
      :webvtt => 'WebVtt',
      :dfxp => 'Dfxp',
      :cheetahcap => 'CheetahCap'
    }

    # @param inputs [Array] list of inputs
    # @param info [Hash] of fields to initialize instance. May contain:
    #        - :subtitle_languages
    # @see TranslationOptions for a list of language codes.
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

    # Length of audio in seconds (mandatory in case of inability to determine it automatically).
    # Used within {Rev::OrderRequest::TranscriptionInfo}
    attr_reader :audio_length_seconds

    # Length of video in seconds (mandatory in case of inability to determine it automatically).
    # Used within {Rev::OrderRequest::CaptionInfo}
    attr_reader :video_length_seconds

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
      @level = level ? level : LEVELS[:final_only]
    end
  end
end
