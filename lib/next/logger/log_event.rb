# frozen_string_literal: true

module Next
  class Logger < Actor
    # @abstract
    # @api private
    LogEvent = Data.define(:progname, :message, :level)
  end
end
