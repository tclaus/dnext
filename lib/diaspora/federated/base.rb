# including this module lets you federate an object at the most basic of level

module Diaspora
  module Federated
    module Base
      # object for local recipients
      def object_to_receive
        self
      end

      # @abstract
      # @note this must return [Array<Person>]
      # @return [Array<Person>]
      def subscribers
        raise 'You must override subscribers in order to enable federation on this model'
      end
    end
  end
end
