# frozen_string_literal: true

module Next
  # A wrapper/delegator for any `ExecutorService` that
  # guarantees serialized execution of tasks.
  #
  # @see [SimpleDelegator](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/delegate/rdoc/SimpleDelegator.html)
  # @see Concurrent::SerializedExecutionDelegator
  # @see Next::SerializedPriorityExecution
  class SerializedPriorityExecutionDelegator < SimpleDelegator
    include ::Concurrent::SerialExecutorService

    def initialize(executor)
      @executor = executor
      @serializer = SerializedPriorityExecution.new
      super(executor)
    end

    def post(*, &task)
      Kernel.raise ArgumentError.new("no block given") unless task
      return false unless running?
      @serializer.post(@executor, *, &task)
    end
  end
end
