# frozen_string_literal: true

require "dry-configurable"
require "logger"

module Next
  class System
    include Dry::Configurable

    setting :logger, default: ::Logger.new($stdout)
    setting :debug do
      setting :lifecycle, default: false
    end

    attr_reader :name
    ROOT_PROPS = Next.props(Root)
    USER_ROOT_PROPS = Next.props(UserRoot)

    attr_reader :root
    private :root

    attr_reader :user_root
    private :user_root

    attr_reader :event_stream
    attr_reader :log
    attr_reader :configx

    class << self
      # Gracefully terminates all known actor systems
      def terminate_all!
        ObjectSpace
          .each_object(self)
          .map { |system| Thread.new { system.terminate! } }
          .each(&:join)
      end
    end

    def initialize(name, config, &configuration)
      @name = name
      @configx = config
      configure(&configuration)

      # Next implements asynchronous logging. However, during the actor system's start and
      # shutdown, asynchronous logging might not always be available.
      #
      # To ensure logging ability during start/shutdown, we log to +$stdout+. Therefore, the logger is
      # protected with a read-write lock.
      initialize_sync_logging

      start_actor_system
      when_terminated.each { log.info("Actor System `#{name}` has been terminated.") }
    end

    # Starts a new actor with given props and name
    #
    def actor_of(props, name = SecureRandom.uuid, timeout: 3)
      promise = Fear::Promise.new
      user_root << UserRoot::CreateActor.new(props:, name:, promise:)
      Fear::Await.result(promise.to_future, timeout).get
    end

    # Gracefully terminates actor system
    def terminate
      initialize_sync_logging
      root.stop
    end

    # Gracefully terminate actor system blocking until termination is finished
    def terminate!
      terminate
      await_termination
    end

    # Returns termination future, so one can set hooks for
    # actor system termination
    def when_terminated
      root.termination_future
    end

    TERMINATION_AWAIT_TIMEOUT = 100_000 * 365 * 24 * 60 * 60
    private_constant(:TERMINATION_AWAIT_TIMEOUT)

    # Blocks till actor system is terminated
    def await_termination
      Fear::Await.result(when_terminated, TERMINATION_AWAIT_TIMEOUT)
    end

    def to_s
      "#<Next::System name=#{name}>"
    end

    private def start_actor_system
      start_root
      start_user_root
      start_event_stream
      initialize_async_logging
    end

    # Starts the root of all the actors in the system
    private def start_root
      @root = Reference.new(ROOT_PROPS, name:, parent: nil, system: self)
      # Root is a parent of self so far
      root << SystemMessages::Initialize.new(nil)
    end

    # Starts the root actor of all the user actors in the system
    private def start_user_root
      @user_root = root.ask!(:initialize_user_root).get
    end

    private def start_event_stream
      event_bus = root.ask!(:initialize_event_bus).get

      @event_stream = EventStream.new(event_bus:)
    end

    private def initialize_sync_logging
      @log = if configx.next.stdout_log_level
        Logging::SyncLog.new(::Logger.new($stdout, level: Logging::SyncLog.level(configx.next.stdout_log_level)))
      else
        Logging::SyncLog.new(::Logger.new(nil))
      end
    end

    private def initialize_async_logging
      root.ask(:initialize_logger).each do |_|
        @log = Logging::AsyncLog.new(self)
      end
    end
  end
end
