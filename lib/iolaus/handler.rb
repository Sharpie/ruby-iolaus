require 'iolaus'
require 'iolaus/util/adapter'

# Base class for handlers
#
# Handlers are attached to requests added to instances of the
# {Iolaus::Client} class. Handlers may implement either
# the {#handle_request} or {#handle_response} methods.
class Iolaus::Handler
  include Iolaus::Util::Adapter

  # @!method handle_request(request)
  #   Process a request before execution
  #
  #   Process a request before it is dispatched to a {Typhoeus::Hydra}
  #   instance.
  #
  #   @param request [Typhoeus::Request] The request object.
  #   @return [Boolean] A boolean value indicating whether the request
  #     should be executed.

  # @!method handle_response(response)
  #   Process a response after execution
  #
  #   Process the results of executing a {Typhoeus::Request}
  #
  #   @param response [Typhoeus::Response] The response object.
  #   @return [Object] The result to set as `handled_response` on the
  #     response object.


  # Return the implemented request handler
  #
  # @return [#call] A callable object, if {#handle_request} is implemented.
  # @return [nil] A `nil` value if {#handle_request} is not implemented.
  def request_handler
    if self.respond_to?(:handle_request)
      self.method(:handle_request)
    else
      nil
    end
  end

  # Return the implemented response handler
  #
  # @return [#call] A callable object, if {#handle_response} is implemented.
  # @return [nil] A `nil` value if {#handle_response} is not implemented.
  def response_handler
    if self.respond_to?(:handle_response)
      self.method(:handle_response)
    else
      nil
    end
  end
end
