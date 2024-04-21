# frozen_string_literal: true

module Next
  class Core
    # @api private
    module FaultTolerance
      # @type module: Core.class

      # Reacts on +SystemMessages::Resume+ message received from a parent.
      def handle_resume(cause)
        if actor_initialized?
          serialized_execution.resume!
          resume_children(cause)
        else
          create_on_failure
        end
      end

      # Reacts on +SystemMessages::Recreate+ message received from parent.
      # Recreates actor loosing state.
      #
      private def handle_recreate(cause)
        if actor_initialized?
          # FIXME: make message available as Context#current_message and pass as message
          actor.around_pre_restart(reason: cause, message: Fear::None)

          self.actor = create_actor

          actor.around_post_restart(reason: cause)
        else
          # log
          create_on_failure
        end
      end

      def handle_suspend
        serialized_execution.suspend!
        suspend_children
      end

      # Reacts on +SystemMessages::Failed+ message received from a child.
      # Applies configured supervision strategy.
      #
      # @see [Next::SupervisorStrategy]
      private def handle_failure(child, cause)
        case child_by_reference(child)
        when Fear::Some
          unless actor.supervisor_strategy.handle_failure(child: child, cause: cause, context: self)
            raise cause
          end
        when Fear::None
          # log miss
        end
      end

      private def create_on_failure
        serialized_execution.resume!
        self.actor = props.__new_actor__(self)
      rescue => error
        self.actor = nil
        handle_processing_error(error)
      end

      # React on failure during the messages processing.
      private def handle_processing_error(error)
        serialized_execution.suspend!
        suspend_children
        parent.tell SystemMessages::Failed.new(child: identity, cause: error)
      end

      private def suspend_children
        children.each do |child|
          child.tell SystemMessages::Suspend
        end
      end

      private def resume_children(cause)
        children.each do |child|
          child.tell SystemMessages::Resume.new(cause)
        end
      end

      # React on +SystemMessages::Terminate+ command from a parent.
      private def handle_terminate
        children.each { |child| stop(child) }
        serialized_execution.suspend!
        finish_terminate
      end

      private def finish_terminate
        actor.around_post_stop
      rescue
        # log it
      ensure
        self.actor = nil
        parent.tell SystemMessages::DeathWatchNotification.new(identity)
      end
    end
  end
end
