# frozen_string_literal: true

module Next
  module SystemMessages
    class Initialize
      include SystemMessage

      attr_reader :parent

      def initialize(parent)
        @parent = parent
        freeze
      end

      def deconstruct
        [parent]
      end

      def deconstruct_key
        {parent:}
      end

      def inspect
        "#<Next::SystemMessages::Initialize parent=#{parent.name}>"
      end
    end
  end
end
