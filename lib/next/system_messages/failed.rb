# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    class Failed
      include SystemMessage

      attr_reader :child
      attr_reader :cause

      def initialize(child:, cause:)
        @child = child
        @cause = cause
      end

      def deconstruct
        [child, cause]
      end

      def deconstruct_key
        {child:, cause:}
      end

      def inspect
        "#<#{self.class.name} child=#{child.name}, cause=#{cause}>"
      end
    end
  end
end
