require 'spec_helper'

require 'iolaus/client'
require 'iolaus/handler/generic'

RSpec.describe(Iolaus::Client) do
  include_context 'stub_http_requests'

  context 'when adding requests' do
    let(:request) { Typhoeus::Request.new('client.iolaus.test') }
    let(:response) { Typhoeus::Response.new }

    it 'stores a reference to its self in adapted data' do
      subject.add_request(request)

      adapted_data = Iolaus::Util::Adapter.get_adapted(request)

      expect(adapted_data).to be
      expect(adapted_data[:client]).to eq(subject)
    end

    it 'applies handlers to requests in order' do
      receiver = double('receiver')
      Typhoeus.stub('client.iolaus.test').and_return(response)

      request.on_complete { receiver.mark('handler2') }
      handler1 = Iolaus::Handler::Generic.new(response_handler: ->(_) { receiver.mark('handler1') })

      subject.add_handler(handler1)
      subject.add_request(request)

      expect(receiver).to receive(:mark).with('handler1').ordered
      expect(receiver).to receive(:mark).with('handler2').ordered

      # FIXME: Should run the client instead of the actual request.
      request.run
    end
  end
end
