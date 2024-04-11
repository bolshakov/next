# frozen_string_literal: true

module Next
  # Similar to +Concurrent::SerializedExecution+, with two distinctions:
  #   * tt prioritize processing of system messages over user messages
  #   * it allows suspending processing of user messages
  #
  # @api private
  class SerializedExecution < Concurrent::Synchronization::LockableObject
    include ::Concurrent::Concern::Logging

    attr_accessor :being_executed
    private :being_executed, :being_executed=
    alias_method :being_executed?, :being_executed

    attr_reader :stash
    private :stash

    def initialize
      super()
      synchronize { ns_initialize }
    end

    # Submit a task to the executor for asynchronous processing.
    # @param executor to be used for this job
    # @param envelope envelope to be passed to the task
    # @yield the asynchronous task to perform
    # @return `true` if the task is queued, `false` if the executor
    #   is not running
    #
    # @raise [ArgumentError] if no task is given
    def post(executor, envelope, &task)
      posts [[executor, envelope, task]]
      true
    end

    # Compared to its superclass, it instantiate a Comparable version of the
    # Job class.
    #
    # @see https://github.com/ruby-concurrency/concurrent-ruby/pull/1045
    def posts(posts)
      return nil if posts.empty?

      jobs = posts.map { |executor, envelope, task| Job.new(executor, envelope, task) }

      take_and_call_job do
        stash.push(*jobs)
      end

      true
    end

    def resume!
      take_and_call_job do
        stash.resume!
      end

      self
    end

    private def take_and_call_job(&before_take)
      job = synchronize do
        before_take.call

        if being_executed?
          Fear.none
        else
          stash.shift.tap do |x|
            self.being_executed = x.present?
          end
        end
      end

      job.each { call_job(_1) }
    end

    def suspend!
      synchronize do
        stash.suspend!
      end
      self
    end

    def suspended?
      stash.suspended?
    end

    private def ns_initialize
      @being_executed = false
      @stash = Stash.new
    end

    private def call_job(job)
      did_it_run = begin
        job.executor.post { work(job) }
        true
      rescue Concurrent::RejectedExecutionError => ex
        false
      end

      # TODO not the best idea to run it myself
      unless did_it_run
        begin
          work job
        rescue => ex
          # let it fail
          log DEBUG, ex
        end
      end
    end

    # ensures next job is executed if any is stashed
    private def work(job)
      job.call
    ensure
      next_job = Fear.none
      synchronize do
        next_job = stash.shift
        next_job.get_or_else { self.being_executed = false }
      end

      next_job.each { call_job _1 }
    end
  end
end
