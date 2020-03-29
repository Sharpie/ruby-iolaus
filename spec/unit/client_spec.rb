require 'spec_helper'

require 'iolaus/client'

RSpec.describe(Iolaus::Client) do
  context 'when adding requests' do
    let(:request) { Typhoeus::Request.new('client.iolaus.test') }

    it 'stores a reference to its self in adapted data' do
      subject.add(request)

      adapted_data = Iolaus::Util::Adapter.get_adapted(request)

      expect(adapted_data).to be
      expect(adapted_data[:client]).to eq(subject)
    end
  end
end
