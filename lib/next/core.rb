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
        @serialized_execution = SerializedPriorityExecution.new
        @props = opts[:props]
        @identity = opts[:identity]
        @actor = props.__new_actor__(self)
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
            when AutoReceivedMessage
              auto_receive_message(message)
            else
              actor.public_send(current_behaviour, message)
            end
          end
        end
      end
    end

    private def auto_receive_message(message)
      case message
      in PoisonPill
        identity << Terminate
      end
    end

    private def current_behaviour
      :receive
    end

    # Schedules blocks to be executed on executor sequentially
    private def schedule_execution(envelope)
      serialized_execution.post(actor.executor, envelope) do |envelope|
        synchronize do
          LocalStorage.with_current_identity(identity) do
            yield(envelope)
          end
        end

        nil
      end
    end
  end
end
