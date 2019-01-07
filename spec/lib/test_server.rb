require 'concurrent'
require 'sinatra/base'

require 'iolaus'

class Iolaus::TestServer < Sinatra::Base
  def self.reset!
    set :retry_counter, Concurrent::AtomicFixnum.new(0)
    set :retry_timer, Concurrent::Atom.new(nil)
    set :retry_at, 2
    set :retry_sleep, 2.0
    set :retry_status, 503
    super
  end

  reset!

  get '/test_retry' do
    settings.retry_counter.increment

    if settings.retry_counter.value == settings.retry_at
      settings.retry_timer.reset(Concurrent::ScheduledTask.execute(settings.retry_sleep) { true })
    end

    if settings.retry_timer.value && !settings.retry_timer.value.complete?
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      remaining = (settings.retry_timer.value.schedule_time - now)

      [settings.retry_status,
       {'Content-Type' => 'text/plain',
        'Retry-After' => remaining.ceil.to_s,
        'Date' => Time.now.utc.rfc2822},
       'Retry after %<remaining>.2f seconds' % {remaining: remaining}]
    else
      [200,
       {'Content-Type' => 'text/plain',
        'Date' => Time.now.utc.rfc2822},
        "The count is: #{settings.retry_counter.value}"]
    end
  end
end

# Boot the server if this file is run directly by Ruby.
if File.expand_path(__FILE__) == File.expand_path($PROGRAM_NAME)
  Iolaus::TestServer.run!
end
