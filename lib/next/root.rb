# frozen_string_literal: true

module Next
  class Root < Actor
    def receive(message)
      case message
      in :initialize_user_root
        sender << context.actor_of(UserRoot.props, "user")
      in :initialize_event_bus
        sender << context.actor_of(EventBus.props, "event_stream")
      in :initialize_logger
        sender << context.actor_of(Logger.props(logger: context.system.config.logger), "logger")
      end
    end
  end
end
