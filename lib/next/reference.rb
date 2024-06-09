# frozen_string_literal: true

# require "fear"
require "concurrent"
require "fear"

module Next
  # Actor reference. Use it to communicate with an actor. It's save to
  # pass a reference as a message to another actor.
  #
  #   worker = system.actor_of(props, 'worker') #=> Next::Reference
  #   worker.tell("do the job")
  #
  # @api private
  class Reference
    attr_reader :name
    attr_reader :props

    attr_reader :core
    protected :core

    attr_reader :parent
    protected :parent

    def initialize(props, parent:, system:, name: SecureRandom.uuid)
      @name = name.to_s
      @parent = parent
      @core = start_actor(parent:, system:, props:)
      freeze
    end

    # Put message into actor's queue. It's not guaranteed that an actor
    # process the messages immediately.
    #
    # @param message
    # @param sender who's sending the message. By default it's current actor
    def tell(message, sender = LocalStorage.current_identity)
      accepting_messages(message:, sender:) do |message, sender|
        core.process_envelope Envelope.new(message:, sender:)
      end

      self
    end

    alias_method :<<, :tell

    # Sends a message and returns response
    #
    # @param message
    # @param sender  who's sending the message. By default it's current actor
    # @return [Fear::Future]
    def ask(message, sender = LocalStorage.current_identity)
      promise = Fear::Promise.new

      accepting_messages(message:, sender:) do |message, sender|
        ask_support = core
          .actor_of(AskSupport.props(promise))
          .tell(AskSupport::Ask.new(self, message))

        # This actor is supervising AskSupport
        self << SystemMessages::Supervise.new(ask_support)
      end

      promise.to_future
    end

    def ask!(message, sender = LocalStorage.current_identity, timeout: config.next.actor.creation_timeout)
      case ask(message, sender).then { Fear::Await.result(_1, timeout) }
      in Fear::Success(value)
        Fear.some(value)
      in Fear::None
        Fear.none
      end
    rescue Timeout::Error
      Fear.none
    end

    def path
      if core.parent.nil? # root actor
        ["next:/", name].join("/")
      else
        [core.parent.path, name].join("/")
      end
    end

    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        name == other.name &&
        parent == other.parent
    end

    def to_s
      "#<Next::Reference name=#{name}>"
    end
    alias_method :inspect, :to_s

    # @api private
    def stop
      tell(SystemMessages::Terminate)

      core.termination_future
    end

    # @api private
    def termination_future = core.termination_future

    def terminated? = termination_future.completed?

    private def start_actor(parent:, system:, props:)
      Core.new(props:, identity: self, parent:, system:)
    end

    private def accepting_messages(message:, sender:)
      if message.is_a?(SystemMessage) || core.running?
        yield(message, sender)
      elsif self != core.system.event_stream.event_bus
        core.system.event_stream.publish(DeadLetter.new(sender:, message:, recipient: self))
      end
    end

    private def config = core.system.config
  end
end
