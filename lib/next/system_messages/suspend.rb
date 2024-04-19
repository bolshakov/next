# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    Suspend = SingletonObject.new("Next::SystemMessages::Suspend").extend(SystemMessage)
  end
end
