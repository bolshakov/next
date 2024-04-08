# frozen_string_literal: true

module Next
  # Queue implementation that behaves similar to Array#push when the method is
  # called without arguments.
  #
  # @api private
  class NonConcurrentPriorityQueue < ::Concurrent::Collection::NonConcurrentPriorityQueue
    def push(*elements)
      if elements.empty?
        self
      else
        super(*elements)
      end
    end
  end
end
