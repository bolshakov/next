# frozen_string_literal: true

module Next
  module SystemMessages
    # Messages sent to setup actor supervision
    class Supervise
      include SystemMessage

      attr_reader :child

      def initialize(child)
        @child = child
        freeze
      end

      def deconstruct
        [@child]
      end

      def deconstruct_key
        {child: @child}
      end

      def inspect
        "#<#{self.class.name} child=#{child.name}>"
      end
    end
  end
end
