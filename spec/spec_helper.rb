require 'bundler/setup'
require 'iolaus'
require 'typhoeus'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require_relative 'lib/test_server'
RSpec.shared_context 'test_server' do
  before(:each) do
    settings = @test_server_settings || {}
    @test_server = Thread.new do
      Iolaus::TestServer.run!(@test_server_settings)
    end

    until Iolaus::TestServer.running? do
      sleep(0.1)
    end
  end

  after(:each) do
    Iolaus::TestServer.stop!
    @test_server.join
    Iolaus::TestServer.reset!
  end
end
