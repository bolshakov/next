# frozen_string_literal: true

module Next
  # @api private
  module LocalStorage
    module_function

    CURRENT_IDENTITY = :current_identity
    SENDER = :sender

    def with_current_identity(reference)
      Thread.current[CURRENT_IDENTITY] = reference
      yield
    ensure
      Thread.current[CURRENT_IDENTITY] = nil
    end

    def with_sender(reference)
      Thread.current[SENDER] = reference
      yield
    ensure
      Thread.current[SENDER] = nil
    end

    def current_identity
      Thread.current[CURRENT_IDENTITY]
    end

    def sender
      Thread.current[SENDER]
    end
  end
end
