# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    Resume = Data.define(:caused_by_failure).include(SystemMessage)
  end
end
