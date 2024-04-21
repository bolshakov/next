# frozen_string_literal: true

module Next
  # Nexus - is an underlying actor implementation. It should never be used by
  # end users. The only public interface available to the end-user is +Next::ActorContext+
  #
  # @api private
  class Core < ::Concurrent::Synchronization::LockableObject
    include Context
    include FaultTolerance

    attr_reader :serialized_execution
    private :serialized_execution

    attr_reader :props
    private :props

    def initialize(opts = {})
      super()
      synchronize do
        @serialized_execution = SerializedExecution.new.tap(&:suspend!)
        @props = opts[:props]
        @identity = opts[:identity]
        @parent = opts[:parent]
        @system = opts[:system]
      end
    end

    # One processing step
    #   * process all system messages
    #   * process one user message
    def process_envelope(envelope)
      schedule_execution(envelope) do |envelope|
        case envelope
        in Envelope(message, sender)
          LocalStorage.with_sender(sender) do
            case message
            in AutoReceivedMessage
              auto_receive_message(message)
            in SystemMessage
              process_system_message(message)
            else
              process_message(message)
            end
          rescue => error
            handle_processing_error(error)
          end
        end
      end
    end

    private def process_system_message(message)
      case message
      in SystemMessages::DeathWatchNotification(child)
        handle_death_watch_notification(child)
      in SystemMessages::Failed(child, cause)
        handle_failure(child, cause)
      in SystemMessages::Initialize(parent)
        initialize_actor(parent)
      in SystemMessages::Recreate(cause)
        handle_recreate(cause)
      in SystemMessages::Resume(cause)
        handle_resume(cause)
      in SystemMessages::Supervise(child)
        supervise(child)
      in SystemMessages::Suspend
        handle_suspend
      in SystemMessages::Terminate
        handle_terminate
      end
    end

    private def process_message(message)
      actor.public_send(current_behaviour, message)
    end

    private def auto_receive_message(message)
      case message
      in PoisonPill
        identity << SystemMessages::Terminate
      end
    end

    private def current_behaviour
      :receive
    end

    # Schedules blocks to be executed on executor sequentially
    private def schedule_execution(envelope)
      serialized_execution.post(props.executor, envelope) do |envelope|
        synchronize do
          LocalStorage.with_current_identity(identity) do
            yield(envelope)
          end
        end

        nil
      end
    end

    private def handle_death_watch_notification(child)
      child_by_reference(child).each do
        remove_child(child)
      end
    end

    private def supervise(child)
      add_child(child)
      child << SystemMessages::Initialize.new(identity)
    end

    private def initialize_actor(parent)
      self.parent = parent
      serialized_execution.resume!
      self.actor = props.__new_actor__(self)
      actor.around_pre_start
    rescue
      raise ActorInitializationError.new("exception during creation", identity)
    end

    private def actor
      @actor || raise(ActorInitializationError.new("actor not initialized", identity))
    end

    private def actor_initialized?
      !@actor.nil?
    end

    private def actor=(value)
      @actor = value
    end
  end
end
