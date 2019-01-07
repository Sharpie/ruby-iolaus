require 'singleton'
require 'time'
require 'thread'
require 'uri'

require 'concurrent'
require 'typhoeus'

require 'iolaus/handlers'
require 'iolaus/util/http'

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
  include Iolaus::Util::HTTP

  # The HTTP status codes for which a Retry-After header will be checked
  #
  # @return [Array<Integer>]
  RETRY_STATUSES = [429, 503]

  def initialize
    @lock = Mutex.new
    @state = {}
  end

  # Handler for Typhoeus.before that checks for pending timers
  #
  # @param request [Typhoeus::Request] A Typhoeus request instance.
  #
  # @return [true]
  def handle_before(request)
    hostname = hostname_for(request)

    # No-op in case of unparsable request URL.
    return true if hostname.nil?

    wait_for(hostname)
    true
  end

  # Check a Typhoeus::Response for 429 or 503 error codes
  #
  # This handler checks a Typhoeus::Response instance for 429 or 503 error
  # codes that include a `Retry-After` header. If the code and headers are
  # matched, then a timer is set for the hostname of the request.
  #
  # @param response [Typhoeus::Response] A response to a Typhoeus::Request.
  #
  # @return [Typhoeus::Response] The response instance, unmodified.
  def handle_response(response)
    return response unless RETRY_STATUSES.include?(response.response_code)

    retry_at = compute_retry_at(response.headers['Date'],
                                response.headers['Retry-After'])
    return response if retry_at.nil?

    hostname = hostname_for(response.request)
    # No-op in case of unparsable request URL.
    return response if hostname.nil?

    set_timer(hostname, retry_at)
    # Send the request back to the queue.
    response.request.hydra.queue(response.request)

    response
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
  # @param retry_at [Time] A time at which requests should be retried. It is
  #   critically important that this value be calculated using external data
  #   sources, such as the `Date` and `Retry-After` headers of a HTTP response.
  #   Otherwise, the Ruby Global VM Lock may interoduce unexpected drift.
  #
  # @return [Concurrent::ScheduledTask<Time>] The timer currently set for the
  #   hostname. The `value` method should return the Time at which the timer
  #   finished waiting.
  def set_timer(hostname, retry_at)
    @lock.synchronize do
      timer = @state[hostname]

      if timer.nil? || (timer.complete? && (timer.value < retry_at))
        timer = create_timer(retry_at - Time.now)
        @state[hostname] = timer
      end

      timer
    end
  end

  # Return any pending timer set for a hostname
  #
  # @return [Concurrent::ScheduledTask<Time>, nil] The timer currently set
  #  for the hostname, if one exists.
  def get_timer(hostname)
    @lock.synchronize { @state[hostname] }
  end

  # Wait for any pending timers to complete on a hostname
  #
  # @param hostname [String] A string containing the hostname to check for
  #   pending timers.
  #
  # @return [void] Returns immediately if no active timer is present. Returns
  #   after sleeping if a timer is counting down.
  def wait_for(hostname)
    timer = get_timer(hostname)

    return if timer.nil? || timer.complete?

    timer.wait
  end

  private

  def create_timer(wait_secs)
    # NOTE: Add an extra second to ensure we wait long enough for an API
    #       rate limit to reset.
    wait = [(wait_secs + 1.0), 0.0].max
    Concurrent::ScheduledTask.execute(wait) { Time.now }
  end

  def hostname_for(request)
    url = case request.base_url
          when String
            URI.parse(request.base_url) rescue nil
          when URI
            request.base_url
          else
            nil
          end

    # FIXME: Log a warning if nil as something has gone weird.
    (url.nil?) ? nil : url.hostname
  end
end

Typhoeus.before.unshift(Iolaus::Handlers::Throttle.instance.method(:handle_before))
