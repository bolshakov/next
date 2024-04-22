# frozen_string_literal: true

module Next
  class System
    attr_reader :name
    ROOT_PROPS = Next.props(Root)
    USER_ROOT_PROPS = Next.props(UserRoot)

    attr_reader :root
    private :root

    attr_reader :user_root
    private :user_root

    class << self
      # Gracefully terminates all known actor systems
      def terminate_all!
        ObjectSpace
          .each_object(self)
          .map { |system| Thread.new { system.terminate! } }
          .each(&:join)
      end
    end

    def initialize(name)
      @name = name

      start_actor_system
      when_terminated.each { puts "\nActor System `#{name}` has been terminated." }

      freeze
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

    private def start_actor_system
      start_root
      start_user_root
    end

    # Starts the root of all the actors in the system
    private def start_root
      @root = Reference.new(ROOT_PROPS, name:, parent: nil, system: self)
      # Root is a parent of self so far
      root << SystemMessages::Initialize.new(@root)
    end

    # Starts the root actor of all the user actors in the system
    private def start_user_root
      @user_root = Reference.new(USER_ROOT_PROPS, name: "user", parent: @root, system: self)

      root << SystemMessages::Supervise.new(user_root)
    end
  end
end
