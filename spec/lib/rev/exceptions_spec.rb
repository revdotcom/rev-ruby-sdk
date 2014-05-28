require_relative '../../spec_helper'

describe 'Exceptions' do
  it 'has INVALID_MEDIA_LENGTH' do
    Rev::OrderRequestErrorCodes::INVALID_MEDIA_LENGTH.must_equal Rev::OrderRequestErrorCodes::INVALID_AUDIO_LENGTH
  end
end

