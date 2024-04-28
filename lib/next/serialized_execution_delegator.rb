# frozen_string_literal: true

module Next
  # A wrapper/delegator for any `ExecutorService` that
  # guarantees serialized execution of tasks.
  #
  # @see [SimpleDelegator](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/delegate/rdoc/SimpleDelegator.html)
  # @see Concurrent::SerializedExecutionDelegator
  # @see Next::SerializedExecution
  class SerializedExecutionDelegator < SimpleDelegator
    include ::Concurrent::SerialExecutorService

    def initialize(executor)
      @executor = executor
      @serializer = SerializedExecution.new
      super(executor)
    end

    def suspend!
      @serializer.suspend!
      self
    end

    def resume!
      @serializer.resume!
      self
    end

    def post(envelope, &task)
      Kernel.raise ArgumentError.new("no block given") unless task
      return false unless running?
      @serializer.post(@executor, envelope, &task)
    end
  end
end
