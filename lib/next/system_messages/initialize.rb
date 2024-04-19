# frozen_string_literal: true

module Next
  module SystemMessages
    Initialize = Data.define(:parent).include(SystemMessage)
  end
end
