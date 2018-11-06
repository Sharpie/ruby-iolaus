require 'time'

require 'iolaus/util'

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
  # @return [nil] Returns `nil` when the `header_value` can't be
  #   parsed as an Integer or RFC 2822 date.
  def parse_retry_after_header(header_value)
    retry_after = begin
                    Integer(header_value)
                  rescue TypeError, ArgumentError
                    begin
                      Time.rfc2822(header_value)
                    rescue ArgumentError
                      return nil
                    end
                  end

    case retry_after
    when Integer
      retry_after
    when Time
      sleep = (retry_after - Time.now).to_i
      (sleep > 0) ? sleep : 0
    end
  end
end
