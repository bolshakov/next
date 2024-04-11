# frozen_string_literal: true

module Next
  # @api private
  Envelope = Data.define(:message, :sender) do
    def system_message?
      # @type self: Envelope
      message.is_a?(SystemMessage)
    end
  end
end
