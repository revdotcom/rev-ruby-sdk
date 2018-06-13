require_relative '../../../spec_helper'

GLOSSARY_ENTRIES_LIMIT_TEST = 1000
GLOSSARY_ENTRY_LENGTH_LIMIT_TEST = 255
SPEAKER_ENTRIES_LIMIT_TEST = 100
SPEAKER_ENTRY_LENGTH_LIMIT_TEST = 15
SUPPORTED_ACCENTS_COUNT = 8

describe 'OrderRequest' do

  it 'defaults to standard TAT guarantee' do
    order = Rev::OrderRequest.new({})
    order.non_standard_tat_guarantee.must_equal false
  end

  it 'accepts non standard TAT guarantee flag during init' do
    non_standard_tat_guarantee = true
    order = Rev::OrderRequest.new({ 'non_standard_tat_guarantee' => non_standard_tat_guarantee })
    order.non_standard_tat_guarantee.must_equal non_standard_tat_guarantee
  end

  it 'has caption options' do
    order = Rev::OrderRequest.new({})
    order.must_respond_to :caption_options
  end

  describe 'InputOptions' do
    it 'is ApiSerializable' do
      options = Rev::InputOptions.new([{}], {})
      options.must_be_kind_of Rev::ApiSerializable
    end

    it 'requires non-empty inputs' do
      proc { Rev::InputOptions.new([]) }.must_raise ArgumentError
    end

    it 'requires non-nil inputs' do
      proc { Rev::InputOptions.new(nil) }.must_raise ArgumentError
    end

    it 'sets inputs from init' do
      inputs = ['foo']
      options = Rev::InputOptions.new(inputs)
      options.inputs.must_equal inputs
    end
  end

  describe 'TranscriptionOptions' do
    it 'is InputOptions' do
      inputs = create_input()
      options = Rev::TranscriptionOptions.new(inputs, {})
      options.must_be_kind_of Rev::InputOptions
    end

    it 'rejects glossary of invalid size' do
      oversize_glossary = ['testing']*(GLOSSARY_ENTRIES_LIMIT_TEST + 1)
      inputs = create_input(glossary: oversize_glossary)
      proc { Rev::TranscriptionOptions.new(inputs) }.must_raise ArgumentError
    end

    it 'rejects glossary if any terms are too long' do
      oversize_glossary_term = "A" * (GLOSSARY_ENTRY_LENGTH_LIMIT_TEST + 1)
      inputs = create_input(glossary: [oversize_glossary_term])
      proc { Rev::TranscriptionOptions.new(inputs) }.must_raise ArgumentError
    end

    it 'rejects speaker list of invalid size' do
      oversize_speakers = ['testing']*(SPEAKER_ENTRIES_LIMIT_TEST + 1)
      inputs = create_input(speakers: oversize_speakers)
      proc { Rev::TranscriptionOptions.new(inputs) }.must_raise ArgumentError
    end

    it 'rejects speaker names if name is too long' do
      oversize_speaker_name = "A" * (SPEAKER_ENTRY_LENGTH_LIMIT_TEST + 1)
      inputs = create_input(speakers: [oversize_speaker_name])
      proc { Rev::TranscriptionOptions.new(inputs) }.must_raise ArgumentError
    end

    it 'rejects invalid accents' do
      inputs = create_input(accents: ['invalid'])
      proc { Rev::TranscriptionOptions.new(inputs) }.must_raise ArgumentError
    end

    it 'rejects accents when theres more listed than supported' do
      accents = [Rev::Input::SUPPORTED_ACCENTS[:american_neutral]]*(SUPPORTED_ACCENTS_COUNT + 1)
      inputs = create_input(accents: accents)
      proc { Rev::TranscriptionOptions.new(inputs) }.must_raise ArgumentError
    end
  end

  describe 'CaptionOptions' do
    it 'is InputOptions' do
      inputs = create_input()
      options = Rev::CaptionOptions.new(inputs, {})
      options.must_be_kind_of Rev::InputOptions
    end

    it 'has output file formats attribute' do
      inputs = create_input()
      options = Rev::CaptionOptions.new(inputs, {})
      options.must_respond_to :output_file_formats
    end

    it 'has output file formats hash' do
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:subrip].must_equal 'SubRip'
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:scc].must_equal 'Scc'
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:mcc].must_equal 'Mcc'
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:ttml].must_equal 'Ttml'
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:qttext].must_equal 'QTtext'
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:transcript].must_equal 'Transcript'
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:webvtt].must_equal 'WebVtt'
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:dfxp].must_equal 'Dfxp'
      Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:cheetahcap].must_equal 'CheetahCap'
    end

    it 'rejects unknowns file formats' do
      inputs = create_input()
      proc { Rev::CaptionOptions.new(inputs, { :output_file_formats => ['invalid'] }) }.must_raise ArgumentError
    end

    it 'accepts valid file formats' do
      inputs = create_input()
      order = Rev::CaptionOptions.new(inputs, { :output_file_formats => [Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:scc]] })
      order.output_file_formats.length.must_equal 1
      order.output_file_formats[0].must_equal Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:scc];
    end

    it 'rejects glossary of invalid size' do
      oversize_glossary = []
      for x in 0..GLOSSARY_ENTRIES_LIMIT_TEST do
        oversize_glossary << 'testing'
      end
      inputs = create_input(glossary: oversize_glossary)
      proc { Rev::CaptionOptions.new(inputs) }.must_raise ArgumentError
    end

    it 'rejects glossary if any terms are too long' do
      oversize_glossary_term = "A" * (GLOSSARY_ENTRY_LENGTH_LIMIT_TEST + 1)
      inputs = create_input(glossary: [oversize_glossary_term])
      proc { Rev::CaptionOptions.new(inputs) }.must_raise ArgumentError
    end

    it 'rejects speaker names of invalid size' do
      oversize_speakers = []
      for x in 0..SPEAKER_ENTRIES_LIMIT_TEST do
        oversize_speakers << 'testing'
      end
      inputs = create_input(speakers: oversize_speakers)
      proc { Rev::CaptionOptions.new(inputs) }.must_raise ArgumentError
    end

    it 'rejects speaker names if name is too long' do
      oversize_speaker_name = "A" * (SPEAKER_ENTRY_LENGTH_LIMIT_TEST + 1)
      inputs = create_input(speakers: [oversize_speaker_name])
      proc { Rev::CaptionOptions.new(inputs) }.must_raise ArgumentError
    end
  end # CaptionOptions

  describe 'Notification' do
    it 'Defaults level' do
      notification = Rev::Notification.new('http://example.com/')
      notification.level.must_equal Rev::Notification::LEVELS[:final_only]
    end
  end # Notification
end
