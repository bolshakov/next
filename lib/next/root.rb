# frozen_string_literal: true

require "logger"

module Next
  class Root < Actor
    def receive(message)
      case message
      in :initialize_user_root
        sender << context.actor_of(UserRoot.props, "user")
      in :initialize_event_bus
        sender << context.actor_of(EventBus.props, "event_stream")
      in :initialize_logger
        sender << context.actor_of(Logger.props(logger: instantiate_logger), "logger")
      end
    end

    private def instantiate_logger
      logdev = context.system.configx.next.logger
      case logdev
      in "stdout"
        ::Logger.new($stdout)
      in ::Logger
        logdev
      else
        ::Logger.new(logdev)
      end
    end
  end
end
