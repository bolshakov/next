# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    class Recreate
      include SystemMessage

      attr_reader :cause

      def initialize(cause)
        @cause = cause
        freeze
      end

      def deconstruct
        [cause]
      end

      def deconstruct_key
        {cause:}
      end

      def inspect
        "#<#{self.class.name} cause=#{cause.inspect}>"
      end
    end
  end
end
