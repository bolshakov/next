# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    class Suspend
      include SystemMessage

      def inspect
        "#<#{self.class.name}>"
      end
    end
  end
end
