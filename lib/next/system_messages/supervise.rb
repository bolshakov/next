# frozen_string_literal: true

module Next
  module SystemMessages
    # Messages sent to setup actor supervision
    Supervise = Data.define(:child).include(SystemMessage)
  end
end
