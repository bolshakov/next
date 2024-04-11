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

    def initialize(name)
      @name = name

      start_actor_system
      freeze
    end

    # Starts a new actor with given props and name
    #
    def actor_of(props, name = SecureRandom.uuid, timeout: 3)
      promise = Fear::Promise.new
      user_root << UserRoot::CreateActor.new(props:, name:, promise:)
      Fear::Await.result(promise.to_future, timeout).get
    end

    private def start_actor_system
      start_root
      start_user_root
    end

    # Starts the root of all the actors in the system
    private def start_root
      @root = Reference.new(ROOT_PROPS, name: "root")
      # Root is a parent of self so far
      root << SystemMessages::Initialize.new(@root)
    end

    # Starts the root actor of all the user actors in the system
    private def start_user_root
      @user_root = Reference.new(USER_ROOT_PROPS, name: "user")

      root << SystemMessages::Supervise.new(user_root)
    end
  end
end
