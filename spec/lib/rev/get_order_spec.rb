require_relative '../../spec_helper'

describe 'GET /orders/{order_num}' do
  let(:client) { Rev.new('welcome', 'AAAAAu/YjZ3phXU5FsF35yIcgiA=', 'www.revtrunk.com') }

  describe 'Transcription' do
    before do
      VCR.insert_cassette 'get_tc_order'
    end

    it 'must get an order by given order number' do
      client.get_order('TC0233908691').wont_be_nil

      assert_requested :get, /.*\/api\/v1\/orders\/TC0233908691/, :times => 1
    end

    describe 'loaded order' do
      let(:order) { client.get_order('TC0233908691') }

      it 'must have basic attributes' do
        order.order_number.must_equal 'TC0233908691'
        order.price.must_equal 10.0
        order.status.must_equal 'Finding Transcriptionist'
        order.client_ref.must_equal 'XC123'
      end

      it 'must have comments' do
        order.comments.size.must_equal 1
        order.comments.first.by.must_equal 'Admin Admin'
        order.comments.first.text.must_be_empty
        order.comments.first.timestamp.day.must_equal 6
        order.comments.first.timestamp.month.must_equal 9
        order.comments.first.timestamp.year.must_equal 2013
      end

      it 'must have attachments' do
        order.attachments.size.must_equal 1
        order.attachments.first.kind.must_equal 'media'
      end

      it 'must have transcription info' do
        order.transcription.total_length.must_equal 10
        order.transcription.verbatim.must_equal false
        order.transcription.timestamps.must_equal false
      end
    end
  end

  describe 'Translation' do
    before do
      VCR.insert_cassette 'get_tr_order'
    end

    describe 'loaded order' do
      let(:order) { client.get_order('TR0116711100') }

      it 'must have translation info' do
        order.translation.total_word_count.must_equal 2
        order.translation.source_language_code.must_equal 'cs'
        order.translation.destination_language_code.must_equal 'en'
      end
    end
  end

  after do
    VCR.eject_cassette
  end
end