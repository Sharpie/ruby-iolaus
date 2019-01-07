require 'spec_helper'
require 'typhoeus'
require 'iolaus/handlers/throttle'

RSpec.describe(Iolaus::Handlers::Throttle) do
  subject { described_class.instance }

  context 'when submitting more requests than a server will allow' do
    before(:each) do
      @test_server_settings = {bind: '127.0.0.1',
                               port: '9462'}
    end
    include_context 'test_server'

    let(:hydra) { Typhoeus::Hydra.new({max_concurrency: 3}) }
    let(:requests) do
      (1..3).map do |_|
        req = Typhoeus::Request.new('http://127.0.0.1:9462/test_retry',
                                    {method: :get})
      end
    end

    it 'retries requests until they succeed' do
      requests.each do |r|
        r.on_failure(&subject.method(:handle_response))
        hydra.queue(r)
      end
      runner = Thread.new { hydra.run }

      # Give the requests some time to hit the server.
      sleep(0.5)

      timer = subject.get_timer('127.0.0.1')
      expect(timer).not_to be_complete

      # Wait for requests to complete.
      runner.join
      expect(requests.map(&:response)).to all(be_success)
    end
  end
end
