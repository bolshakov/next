# # frozen_string_literal: true
#
module Next
  class SerializedExecution
    # Stash that prioritize system messages over user messages.
    # When suspended, it returns only system jobs
    # @api private
    class Stash
      attr_reader :system_jobs
      private :system_jobs
      attr_reader :user_jobs
      private :user_jobs

      attr_accessor :suspended
      private :suspended, :suspended=

      # @param suspended you can instantiate a suspended stash by passing +suspended: true+
      def initialize(suspended: false)
        @system_jobs = []
        @user_jobs = []
        @suspended = suspended
      end

      def suspend!
        self.suspended = true
        self
      end

      def resume!
        self.suspended = false
        self
      end

      def suspended?
        suspended
      end

      def drain
        drained_jobs = @user_jobs
        @user_jobs = []
        drained_jobs
      end

      def push(*envelops)
        system_messages, user_messages = envelops.partition { _1.envelope.system_message? }
        system_jobs.push(*system_messages)
        user_jobs.push(*user_messages)

        self
      end

      def shift
        if system_jobs.empty? && !suspended?
          Fear.option(user_jobs.shift)
        else
          Fear.option(system_jobs.shift)
        end
      end

      def to_a
        system_jobs + user_jobs
      end

      def to_s
        "#<Next::SerializedExecution::Stash #{to_a.inspect}>"
      end

      alias_method :inspect, :to_s

      def empty?
        system_jobs.empty? && user_jobs.empty?
      end
    end
  end
end
