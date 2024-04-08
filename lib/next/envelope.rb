# frozen_string_literal: true

module Next
  # @api private
  class Envelope
    include Comparable

    class << self
      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      end
    end

    attr_reader :message
    attr_reader :posted_at
    attr_reader :sender

    def initialize(message:, sender:, posted_at: self.class.current_time)
      @message = message
      @sender = sender
      @posted_at = posted_at
    end

    # SystemMessages have higher priority than user messages
    def <=>(other)
      return unless other.is_a?(Envelope)

      if message.is_a?(SystemMessage) && other.message.is_a?(SystemMessage)
        posted_at <=> other.posted_at
      elsif message.is_a?(SystemMessage)
        1
      elsif other.message.is_a?(SystemMessage)
        -1
      else
        posted_at <=> other.posted_at
      end
    end

    def deconstruct
      [message, sender]
    end

    def deconstruct_keys(keys = nil)
      if keys.nil?
        {message:, sender:}
      else
        {message:, sender:}.slice(*keys)
      end
    end
  end
end
