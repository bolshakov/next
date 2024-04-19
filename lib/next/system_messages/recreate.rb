# frozen_string_literal: true

module Next
  module SystemMessages
    # @api private
    Recreate = Data.define(:cause).include(SystemMessage)
  end
end
