# frozen_string_literal: true

# Testing actor with the following protocol:
#
#   * +[:create_supervised, Next::Props]+ creates a child actor with the given props
#     and send reference back to sender.
#   * +[:find_supervised, String]+ finds child by name and sends +Fear::Option<Reference>+
#     back to sender.
#   * +:increment+ increment counter starting from 1 and send result back to sender.
#   * +:counter+ gets counter value
#   * +:fail+ fails with +NoMethodError+
#
class SupervisionTestingActor < Next::Actor
  class << self
    # @param supervisor_strategy [Next::SupervisorStrategy, nil]
    #   can be configured with a custom supervision strategy. If not passed, it uses default one.
    # @param failure_flag [Next::Reference, nil]
    #   A feature flag, that controls if initializer should fail or not.
    #   @see SupervisionTestingFeatureFlag for details
    def props(supervisor_strategy = nil, failure_flag = nil)
      Next.props(
        self,
        supervisor_strategy: supervisor_strategy,
        failure_flag: Fear.option(failure_flag)
      )
    end
  end

  attr_accessor :supervised
  attr_accessor :counter

  # @param supervisor_strategy [Next::SupervisorStrategy, nil]
  # @param failure_flag [Fear::Option<Next::Reference>]
  def initialize(supervisor_strategy:, failure_flag:)
    @supervisor_strategy = supervisor_strategy
    @counter = 1
    if failure_flag.flat_map { _1.ask!(:enabled?) }.include?(true)
      raise NoMethodError
    end
  end

  def receive(message)
    case message
    in [:create_supervised, supervised_props]
      self.supervised = context.actor_of(supervised_props, "#{context.identity.name}'s child")
      sender.tell supervised
    in [:find_supervised, name]
      sender.tell context.child(name)
    in :increment
      self.counter += 1
      sender.tell counter
    in :counter
      sender.tell counter
    in :fail
      raise NoMethodError
    end
  end

  def supervisor_strategy
    @supervisor_strategy || super
  end
end

class TestingSupervisorStrategy < Next::SupervisorStrategy
  def handle_failure(cause:, **)
    true
  end
end

# A "feature flag" actor implements the following protocol:
#   * +true+ enables feature
#   * +false+ disables feature
#   * +:enabled?+ checks if a feature is enabled or not
#
class FeatureFlag < Next::Actor
  class << self
    # @param enabled [Boolean] (false) initial state
    def props(enabled = false)
      Next.props(self, enabled: enabled)
    end
  end

  attr_accessor :enabled

  def initialize(enabled:)
    @enabled = enabled
  end

  def receive(message)
    case message
    when true, false
      self.enabled = message
      sender.tell(:ok)
    when :enabled?
      sender.tell(enabled)
    end
  end
end
