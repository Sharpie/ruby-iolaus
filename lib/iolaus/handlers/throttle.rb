require 'singleton'
require 'thread'

require 'concurrent'

require 'iolaus/handlers'

# Throttle parallel execution in response to server errors
#
# This class implements a handler that throttles the execution of parallel
# requests when a server returns a 429 or 503 status code with a Retry-After
# header set. This class works by installing its self as a before handler
# for all Typhoeus activity and as an `on_failure` handler for requests.
# If a request fails due to a 429 or 503 with `Retry-After` set, then the
# `on_failure` handler registers a timer for the domain name of the request
# URL. Once a timer is registered, any requests to the domain that are
# preparing to execute will block within the `before` handler until the timer
# expires.
#
# This means an entire `Typhoeus::Hydra` can fill up with waiting requests.
# The impact of this can be mitigated by using a seperate Hydra for each
# domain.
class Iolaus::Handlers::Throttle
  include Singleton

  def initialize
    @lock = Mutex.new
    @state = {}
  end

  # Wait for any pending timers to complete on a URL
  #
  # @param hostname [String] A string containing the hostname to check for
  #   pending timers.
  #
  # @return [void] Returns immediately if no active timer is present. Returns
  #   after sleeping if a timer is counting down.
  def wait_for(hostname)
    timer = @lock.synchronize { @state[hostname] }

    return if timer.nil? || timer.complete?

    timer.wait
  end

  # Set a timer on a URL
  #
  # @note If multple concurrent calls are made to this method, then the first
  #   call that sets a timer will "win". All subsequent calls will return the
  #   timer created by the first until that timer finishes executing. This
  #   behavior is based on the assumption that a batch of HTTP requests that
  #   fail with `Retry-After` headers set will all have a similar wait time,
  #   so waiting for the retry specified by the first failing request is
  #   sufficient.
  #
  # @param hostname [String] A string containing the hostname to set the
  #   timer on.
  # @param retry_after [Number] The number of seconds to wait as a floating
  #   point value.
  #
  # @return [Concurrent::ScheduledTask] The timer currently set for the
  #   hostname.
  def set_timer(hostname, retry_after)
    @lock.synchronize do
      timer = @state[hostname]

      if timer.nil? || timer.complete?
        timer = create_timer(retry_after)
        @state[hostname] = timer
      end

      timer
    end
  end

  private

  def create_timer(wait_secs)
    # NOTE: Add an extra second to ensure we wait long enough for an API
    #       rate limit to reset.
    Concurrent::ScheduledTask.execute(wait_secs + 1.0) { wait_secs }
  end
end
