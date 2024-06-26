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

    attr_reader :termination_promise
    private :termination_promise

    attr_reader :termination_future

    attr_writer :terminating
    private :terminating=

    def initialize(opts = {})
      super()
      synchronize do
        @terminating = false
        @termination_promise = Fear::Promise.new
        @termination_future = @termination_promise.to_future
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
            in AutoReceiveMessage
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

    private def log_message(message, handled:)
      if identity.path.start_with?("next://#{system.name}/user/") && identity.name != "test-logs-listener"
        log.debug("received #{handled ? "handled" : "unhandled"} message `#{message.inspect}` from '#{sender&.name || "unknown"}`", identity.name)
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
      catch(:pass) do
        actor.public_send(current_behaviour, message)
        log_message(message, handled: true) if system.config.next.debug.receive
        return
      rescue NoMatchingPatternError => error
        if error.backtrace&.first&.end_with?(":in `#{current_behaviour}'") # This is kind of fragile
          pass
        else
          raise
        end
      end

      system.event_stream.publish(DeadLetter.new(sender:, recipient: identity, message:))
      log_message(message, handled: false) if system.config.next.debug.unhandled
    end

    private def auto_receive_message(message)
      log.debug("received AutoReceiveMessage #{message}", identity.name) if system.config.next.debug.autoreceive
      case message
      in PoisonPill
        identity << SystemMessages::Terminate
      end
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
      finish_terminate
    end

    private def supervise(child)
      # TODO: what if it's being terminated?
      add_child(child)
      child << SystemMessages::Initialize.new(identity)
      log.debug("now supervising #{child}", identity.name) if system.config.next.debug.lifecycle
    end

    private def initialize_actor(parent)
      self.parent = parent
      self.actor = create_actor
      actor.around_pre_start
    rescue
      raise ActorInitializationError.new("exception during creation", identity)
    end

    private def create_actor
      serialized_execution.resume!
      become(Context::DEFAULT_BEHAVIOUR)
      actor = props.__new_actor__(self)

      log.debug("created", identity.name) if system.config.next.debug.lifecycle

      actor
    end

    private def actor
      @actor || raise(ActorInitializationError.new("actor not initialized", identity))
    end

    private def actor_initialized?
      !@actor.nil?
    end

    attr_writer :actor
    private :actor=

    def running? = !(terminated? || terminating?)

    private def terminating? = @terminating

    private def terminated? = @termination_future.completed?
  end
end
