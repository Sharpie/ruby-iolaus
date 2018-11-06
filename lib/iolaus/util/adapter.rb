require 'iolaus/util'

# Set or retrieve data on an object
#
# This module contains methods that can be used to set or retrieve
# data on arbitrary object instances. This allows the behvoior of
# objects to be extended or modified without the use of monkey
# patches.
module Iolaus::Util::Adapter
  VAR_NAME = :'@__iolaus_util_adapter'

  # Add data to an object
  #
  # @param object [Object] An arbitrary Ruby object.
  # @param data [Hash] A hash of data to add.
  #
  # @return [void]
  def add_data(object, data)
    existing_data = get_data(object) || {}
    object.instance_variable_set(VAR_NAME, existing_data.merge(data))
  end

  # Retrieve data from an object
  #
  # @param object [Object] An arbitrary Ruby object.
  #
  # @return [Hash] A hash of data, if set on the object.
  # @return [nil] A `nil` value if no data is set.
  def get_data(object)
    object.instance_variable_get(VAR_NAME)
  end
end
