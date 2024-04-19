# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    Failed = Data.define(:child, :cause).include(SystemMessage)
  end
end
