# frozen_string_literal: true

module Next
  # This is the main logging interface available for user actors.
  #
  # Usage:
  #   class MyActor < Next::Actor
  #     include Next::Logging
  #
  #     def receive(message)
  #       log.info("#{message} received")
  #     end
  #   end
  #
  # There are all common methods available for your disposal:
  #
  #   log.info("message")
  #   log.debug("message")
  #   log.warn("message")
  #   log.error("message")
  #   log.fatal("message")
  #
  # optionally, you can pass the name of the program:
  #
  #   log.info("message", "my actor")
  #
  # Keep in mind that logging is asynchronous and the message timestamp may not necessarily
  # match the time when the logger is called.
  #
  module Logging
    # @type module: Actor.class

    def log
      context.log
    end
  end
end
