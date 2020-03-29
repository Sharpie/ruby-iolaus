require 'iolaus'
require 'iolaus/util/adapter'

# Client for executing batches of HTTP requests in parallel
class Iolaus::Client
  include Iolaus::Util::Adapter

  def initialize
    @request_handlers = []
    @response_handlers = []
  end

  # Add a request to the client
  #
  # @param request [Typhoeus::Request] The request instance to add.
  #
  # @return [void]
  def add_request(request)
    @response_handlers.each {|handler| request.on_complete.unshift(handler) }
    update_adapted(request, {client: self})
  end

  # Add a handler to the client
  #
  # Response handlers are executed as `on_complete` callbacks that are
  # posistioned before any callbacks explicitly set on the request.
  #
  # @param handler [Iolaus::Handler] The handler to add.
  #
  # @return [void]
  def add_handler(handler)
    @request_handlers << handler.request_handler unless handler.request_handler.nil?
    @response_handlers << handler.response_handler unless handler.response_handler.nil?
  end
end
