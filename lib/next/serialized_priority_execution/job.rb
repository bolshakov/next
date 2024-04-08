# frozen_string_literal: true

module Next
  class SerializedPriorityExecution
    class Job
      attr_reader :executor
      attr_reader :args
      attr_reader :block

      def initialize(executor, args, block)
        @executor = executor
        @args = args
        @block = block
      end

      def call
        block.call(*args)
      end

      def <=>(other)
        return unless other.is_a?(Job)

        args <=> other.args
      end
    end
  end
end
