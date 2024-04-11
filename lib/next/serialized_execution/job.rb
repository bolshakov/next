# frozen_string_literal: true

module Next
  class SerializedExecution
    Job = Data.define(:executor, :envelope, :block) do
      def call
        # @type self: Job
        block.call(envelope)
      end
    end
  end
end
