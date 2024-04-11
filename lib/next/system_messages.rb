# frozen_string_literal: true

module Next
  module SystemMessages
    Terminate = SingletonObject.new("Terminate").extend(SystemMessage)
  end
end
