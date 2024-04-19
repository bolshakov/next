# frozen_string_literal: true

module Next
  # Applies one of +Next::SupervisorStrategy::DIRECTIVES+ to the failing child.
  #
  # You can provide different directives to various kinds of errors:
  #
  #   OneForOneStrategy.new do |error|
  #     case
  #     when ZeroDivisionError then SupervisorStrategy::RESUME   # Ignore error. Continue processing messages.
  #     when ArgumentError then SupervisorStrategy::RESTART      # Restart the child. All the accumulated state will
  #                                                              #   be lost.
  #     when NoMethodError then SupervisorStrategy::STOP         # Stop processing messages. Shut down the actor.
  #     else
  #       SupervisorStrategy::ESCALATE                           # Let the parent decide how to handle the error.
  #                                                              #   This is a default strategy
  #     end
  #   end
  #
  class OneForOneStrategy < SupervisorStrategy
    # Restarts or stop a child depending on +restart+ value
    def process_failure(cause:, child:, restart:, context:)
      if restart
        restart_child(child: child, cause: cause, suspend_first: false)
      else
        context.stop(child)
      end
    end
  end
end
