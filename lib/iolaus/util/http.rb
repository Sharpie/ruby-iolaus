require 'time'

require 'iolaus/util'

# Helper methods for handling HTTP requests and responses
module Iolaus::Util::HTTP
  # Parse the value of a Retry-After header
  #
  # Parses a string containing an Integer or RFC 2822 datestamp and returns
  # an integer number of seconds before a request can be retried.
  #
  # @param header_value [String] The value of the Retry-After header.
  #
  # @return [Integer] Number of seconds to wait before retrying the
  #   request. Will be equal to 0 for the case of date that has already
  #   passed.
  # @return [Time] Time at which the request may be retried.
  # @return [nil] Returns `nil` when the `header_value` can't be
  #   parsed as an Integer or RFC 2822 date.
  def parse_retry_after_header(header_value)
    begin
      Integer(header_value)
    rescue TypeError, ArgumentError
      begin
        Time.rfc2822(header_value)
      rescue ArgumentError
        nil
      end
    end
  end

  # Compute a retry time from response headers
  #
  # This method takes a Date header and one or more Retry-After
  # headers and returns a Time at which a request can be retried.
  #
  # @param response_date [nil, String] A Header containing RFC 2822 formatted date.
  # @param retry_after [nil, String, Array<String>] A list of Retry-After headers.
  #
  # @return [Time] A time at which a request may be retried.
  # @return [nil] Returns `nil` if `response_date`, or `retry_after` were missing
  #   or unparsable by {#parse_retry_after_header}.
  def compute_retry_at(response_date, retry_after)
    retry_at = Array(retry_after).map {|h| parse_retry_after_header(h)}.max

    case retry_at
    when Integer
      date = Time.rfc2822(response_date) rescue nil
      return nil if date.nil?

      (date + retry_at)
    when Time
      retry_at
    when nil
      nil
    end
  end
end
