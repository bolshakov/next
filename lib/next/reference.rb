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

    # @param props [Next::Props]
    # @param name [String]
    def initialize(props, name: SecureRandom.uuid)
      @props = props
      @name = name.to_s
      @core = start_actor
      freeze
    end

    # Put message into actor's queue. It's not guaranteed that an actor
    # process the messages immediately.
    #
    # @param message
    # @param sender who's sending the message. By default it's current actor
    def tell(message, sender = LocalStorage.current_identity)
      core.process_envelope Envelope.new(message:, sender:)

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

      ask_support =
        Reference
          .new(AskSupport.props(promise))
          .tell(AskSupport::Ask.new(self, message))

      # This actor is supervising AskSupport
      self << SystemMessages::Supervise.new(ask_support)

      promise.to_future
    end

    def ask!(message, sender = LocalStorage.current_identity, timeout: 3)
      ask(message, sender)
        .then { Fear::Await.result(_1, timeout) }
        .get
    end

    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        name == other.name &&
        props == other.props &&
        core == other.core
    end

    def to_s
      "#<Next::Reference name=#{name}>"
    end
    alias_method :inspect, :to_s

    private def start_actor
      Core.new(props:, identity: self)
    end
  end
end
