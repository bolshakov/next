# frozen_string_literal: true

module Next
  # Applies one of +Next::SupervisorStrategy::DIRECTIVES+ to all children when one of
  # them fails.
  #
  # You can provide different directives to various kinds of errors:
  #
  #   AllForOneStrategy.new do |error|
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
  class AllForOneStrategy < SupervisionStrategy
    # Restarts or stop a child depending on +restart+ value
    def process_failure(cause:, child:, restart:, context:)
      unless context.children.empty?
        if restart
          context.children.each { restart_child(child: _1, cause: cause, suspend_first: true) }
        else
          context.children.each { context.stop(_1) }
        end
      end
    end
  end
end
