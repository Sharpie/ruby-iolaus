require 'iolaus'
require 'iolaus/util/adapter'

# Client for executing batches of HTTP requests in parallel
class Iolaus::Client
  include Iolaus::Util::Adapter

  # Add a request to the client
  #
  # @param request [Typhoeus::Request] The request instance to add.
  #
  # @return [void]
  def add(request)
    update_adapted(request, {client: self})
  end
end
