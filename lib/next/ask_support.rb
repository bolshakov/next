# frozen_string_literal: true

module Next
  # @api private
  class AskSupport < Actor
    Ask = Data.define(:destination, :message)

    class << self
      def props(promise)
        Next::Props.new(self, promise:)
      end
    end

    attr_reader :promise
    private :promise

    def initialize(promise:)
      @promise = promise
    end

    def receive(message)
      case message
      in Ask(destination, question)
        destination.tell(question)
      else
        promise.success(message)
      end
    end
  end
end
