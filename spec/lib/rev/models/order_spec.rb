require_relative '../../../spec_helper'

describe 'Order' do
  let(:cp_order) { 
    Rev::Order.new (
      { 'attachments' => { },
        'comments' => {},
        'caption' => { 'total_length_seconds' => 300 }
      }
    )
  }
  
  it 'has caption info' do
    assert_respond_to cp_order, 'caption'
  end

  it 'parses caption info' do
    assert_kind_of Rev::CaptionInfo, cp_order.caption
  end
  
  it 'has captions attachments' do
    assert_respond_to cp_order, 'captions'
  end
  
  describe 'Attachments' do
    describe 'REPRESENTATIONS' do
      it 'has srt' do
        Rev::Attachment::REPRESENTATIONS[:srt].must_equal 'application/x-subrip'
      end

      it 'has scc' do
        Rev::Attachment::REPRESENTATIONS[:scc].must_equal 'text/x-scc'
      end

      it 'has ttml' do
        Rev::Attachment::REPRESENTATIONS[:ttml].must_equal 'application/ttml+xml'
      end

      it 'has qt' do
        Rev::Attachment::REPRESENTATIONS[:qt].must_equal 'application/x-quicktime-timedtext'
      end
    end
  
    describe 'KINDS' do
      it 'has caption' do
        Rev::Attachment::KINDS[:caption].must_equal 'caption'
      end
    end
  end # Attachments
  
  describe 'CaptionInfo' do
    it 'has total_length_seconds' do
      info = Rev::CaptionInfo.new({})
      assert_respond_to info, 'total_length_seconds'
    end
  end # CaptionInfo
end

