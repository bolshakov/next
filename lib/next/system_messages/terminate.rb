# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    Terminate = SingletonObject.new("Next::SystemMessages::Terminate").extend(SystemMessage)
  end
end
