require 'rev-api/api_serializable'

module Rev
  # Represents Translation or Transcription order.
  # Should have TranslationInfo or TranscriptionInfo, list
  # of comments and attachments. Attributes names reflect
  # API exposed names, but occasional hyphens are replaced
  # with underscores
  class Order < ApiSerializable
    attr_reader :order_number, :price, :status, :attachments, :comments,
      :translation, :transcription, :client_ref

    # @param fields [Hash] hash of order fields parsed from JSON API response
    def initialize(fields)
      super fields
      @attachments = fields['attachments'].map { |attachment_fields| Attachment.new(attachment_fields) }
      @comments = fields['comments'].map { |comment_fields| Comment.new(comment_fields) }
      @translation = TranslationInfo.new(fields['translation']) if fields['translation']
      @transcription = TranscriptionInfo.new(fields['transcription']) if fields['transcription']
    end

    # @return [Array of Attachment] with the kind of "transcript"
    def transcripts
      @attachments.select { |a| a.kind == Attachment::KINDS[:transcript]}
    end

    # @return [Array of Attachment] with the kind of "translation"
    def translations
      @attachments.select { |a| a.kind == Attachment::KINDS[:translation]}
    end

    # @return [Array of Attachment] with the kind of "sources"
    def sources
      @attachments.select { |a| a.kind == Attachment::KINDS[:media]}
    end
  end

  # Order comment, containing author, creation timestamp and text
  class Comment < ApiSerializable
    require 'date'

    attr_reader :by, :timestamp, :text

    # @param fields [Hash] hash of comment fields parsed from JSON API response
    def initialize(fields)
      super fields
      @timestamp = Date.iso8601(fields['timestamp'])
      @text = fields['text'] ? fields['text'] : String.new # right now API gives no 'text' field if text is empty
    end
  end

  # Additional information specific to translation orders,
  # such as word count, languages
  class TranslationInfo < ApiSerializable
    attr_reader :total_word_count, :source_language_code,
      :destination_language_code
  end

  # Additional information specific to transcription orders,
  # such as total length in minutes, verbatim and timestamps flags
  class TranscriptionInfo < ApiSerializable
    attr_reader :total_length, :verbatim, :timestamps
  end

  # Represents order attachment - logical document associated with order
  class Attachment < ApiSerializable
    attr_reader :kind, :name, :id, :audio_length, :word_count, :links

    KINDS = {
      :transcript => 'transcript',
      :translation => 'translation',
      :media => 'media'
    }

    # List of supported mime-types used to request attachment's content
    # within 'Accept' header
    REPRESENTATIONS = {
      :docx => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      :doc => 'application/msword',
      :pdf => 'application/pdf',
      :txt => 'text/plain',
      :youtube => 'text/plain; format=youtube-transcript'
    }

    # @param fields [Hash] fields of attachment fields parsed from JSON API response
    def initialize(fields)
      super fields
      @links = fields['links'].map { |link_fields| Link.new(link_fields) }
    end

    # @param ext [Symbol] extension
    # @return [String] mime-type for requested extension
    def self.representation_mime(ext)
      REPRESENTATIONS[ext]
    end
  end

  # Link to actual file represented by attachment
  class Link < ApiSerializable
    attr_reader :rel, :href, :content_type
  end

  # Represents a paginated list of orders, including padination info.
  class OrdersListPage < ApiSerializable
    attr_reader :total_count, :results_per_page, :page, :orders

    # @param fields [Hash] hash of OrdersListPage fields parsed from JSON API response
    def initialize(fields)
      super fields
      @orders = fields['orders'].map { |order_fields| Order.new(order_fields) }
    end
  end
end
