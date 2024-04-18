# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    class Resume
      include SystemMessage

      attr_reader :caused_by_failure
      private :caused_by_failure

      def initialize(caused_by_failure)
        @caused_by_failure = caused_by_failure
        freeze
      end

      def deconstruct
        [caused_by_failure]
      end

      def deconstruct_key
        {caused_by_failure: caused_by_failure}
      end

      def inspect
        "#<#{self.class.name} caused_by_failure=#{caused_by_failure.inspect}>"
      end
    end
  end
end
