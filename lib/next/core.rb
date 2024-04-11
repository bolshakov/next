# frozen_string_literal: true

module Next
  # Nexus - is an underlying actor implementation. It should never be used by
  # end users. The only public interface available to the end-user is +Next::ActorContext+
  #
  # @api private
  class Core < ::Concurrent::Synchronization::LockableObject
    include Context

    attr_reader :serialized_execution
    private :serialized_execution

    attr_reader :props
    private :props

    attr_reader :actor
    private :actor

    def initialize(opts = {})
      super()
      synchronize do
        @serialized_execution = SerializedExecution.new.tap(&:suspend!)
        @props = opts[:props]
        @identity = opts[:identity]
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
          end
        end
      end
    end

    private def process_system_message(message)
      case message
      in SystemMessages::Supervise(child)
        supervise(child)
      in SystemMessages::Initialize(parent)
        initialize_actor(parent)
      in SystemMessages::Terminate
        handle_terminate
      end
    end

    private def process_message(message)
      raise "actor not initialized" if actor.nil?
      actor.public_send(current_behaviour, message)
    rescue => e
      puts e.inspect
      puts e.backtrace
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

    private def supervise(child)
      children[child.name] = child
      child << SystemMessages::Initialize.new(identity)
    end

    private def initialize_actor(parent)
      self.parent = parent
      serialized_execution.resume!
      @actor = props.__new_actor__(self)
    end

    private def handle_terminate
      # children.each { |child| stop(child) }
      serialized_execution.suspend!
      finish_terminate
    end

    private def finish_terminate
    end
  end
end
