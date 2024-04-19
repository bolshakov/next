# frozen_string_literal: true

module Next
  # Abstract supervision strategy.
  #
  # You're not supposed to inherit from  this class. Use +Next::OneForOneStrategy+ or
  # +Next::AllForOneStrategy+ instead.
  #
  # @abstract
  class SupervisorStrategy
    DIRECTIVES = [
      ESCALATE = :escalate,
      RESTART = :restart,
      RESUME = :resume,
      STOP = :stop
    ].freeze

    public_constant(:DIRECTIVES)
    public_constant(:ESCALATE)
    public_constant(:RESTART)
    public_constant(:RESUME)
    public_constant(:STOP)

    DEFAULT_DECIDER = proc do |error|
      case error
      when ActorInitializationError
        STOP
      else
        RESTART
      end
    end

    class << self
      def default_strategy
        OneForOneStrategy.new(&default_decider)
      end

      def default_decider
        DEFAULT_DECIDER
      end
    end

    attr_reader :decider

    # @example
    #   Next::OneForOneStrategy.new do |error|
    #     case
    #     when NoMethodError then SupervisorStrategy::RESUME
    #     end
    #   end
    #
    def initialize(&decider)
      @decider = decider
    end

    # Restarts or stop a child depending on +restart+ value
    # @abstract should be defined in a concrete strategy
    # @return [bool] indicating whether an error has been handled or not by this strategy
    def process_failure(cause:, child:, restart:, context:)
      raise NotImplementedError
    end

    # @return [bool] indicating whether an error has been handled or not by this strategy
    def handle_failure(cause:, child:, context:)
      case decide(cause)
      in ESCALATE
        # log me
        false
      in RESTART
        process_failure(restart: true, child: child, cause: cause, context: context)
        true
      in RESUME
        resume_child(child: child, cause: cause)
        true
      in STOP
        process_failure(restart: false, child: child, cause: cause, context: context)
        true
      end
    end

    private def decide(cause)
      decider.call(cause) || ESCALATE
    rescue NoMatchingPatternError
      ESCALATE
    end
    # @return [void]
    private def resume_child(child:, cause:)
      child.tell(SystemMessages::Resume.new(cause))
    end

    private def restart_child(child:, cause:, suspend_first:)
      child.tell(SystemMessages::Suspend.new) if suspend_first
      child.tell(SystemMessages::Recreate.new(cause))
    end
  end
end
