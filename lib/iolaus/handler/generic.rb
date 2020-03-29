require 'iolaus/handler.rb'

# A handler that wraps arbitrary callable blocks
class Iolaus::Handler::Generic < Iolaus::Handler
  attr_reader :request_handler
  attr_reader :response_handler

  # Initialize a new generic handler
  #
  # @param request_handler [#call, nil] An optional callable proc or lambda.
  # @param response_handler [#call, nil] An optional callable proc or lambda.
  def initialize(request_handler: nil, response_handler: nil)
    @request_handler = request_handler
    @response_handler = response_handler
  end
end
