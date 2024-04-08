# frozen_string_literal: true

module Next
  # This is prioritized executor backed by the +Concurrent::Collection::NonConcurrentPriorityQueue+
  # The job
  # @api private
  class SerializedPriorityExecution < ::Concurrent::SerializedExecution
    private def ns_initialize
      @being_executed = false
      @stash = NonConcurrentPriorityQueue.new(order: :min)
    end

    # Compared to its superclass, it instantiate a Comparable version of the
    # Job class.
    #
    # @see https://github.com/ruby-concurrency/concurrent-ruby/pull/1045
    def posts(posts)
      return nil if posts.empty?

      jobs = posts.map { |executor, args, task| new_job(args, executor, task) }
      # @type var jobs: Array[Job]

      job_to_post = synchronize do
        if @being_executed
          @stash.push(*jobs)
          nil
        else
          @being_executed = true
          job, *jobs_rest = jobs
          @stash.push(*jobs_rest) unless jobs_rest.empty?
          job
        end
      end

      if job_to_post
        # @type var job_to_post: Job
        call_job job_to_post
      end
      true
    end

    private def new_job(args, executor, task)
      Job.new(executor, args, task)
    end
  end
end
