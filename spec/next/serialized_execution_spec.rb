# frozen_string_literal: true

RSpec.describe Next::SerializedExecution do
  subject(:execution) { Next::SerializedExecutionDelegator.new(executor) }

  let(:executor) { Concurrent::ImmediateExecutor.new }
  let(:pool_termination_timeout) { 10 }
  let(:envelope) { Next::Envelope.new(message: 42, sender: nil) }
  let(:system_envelope) { Next::Envelope.new(message: Object.new.extend(Next::SystemMessage), sender: nil) }

  after(:each) do
    execution.shutdown
    expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
  end

  context "#post" do
    it "raises an exception if no block is given" do
      expect {
        execution.post(envelope)
      }.to raise_error(ArgumentError)
    end

    it "returns true when the block is added to the queue" do
      expect(execution.post(envelope) { nil }).to be_truthy
    end

    it "calls the block with the given arguments" do
      latch = Concurrent::CountDownLatch.new(1)
      expected = nil
      execution.post(envelope) do |e|
        expected = e
        latch.count_down
      end
      latch.wait(0.2)
      expect(expected).to eq(envelope)
    end

    it "does not call the block then suspended" do
      latch = Concurrent::CountDownLatch.new(1)
      execution.suspend!
      execution.post(envelope) do |e|
        latch.count_down
      end
      expect(latch.wait(0.1)).to be_falsey
    end

    it "calls the block then suspended if system message received" do
      latch = Concurrent::CountDownLatch.new(1)
      execution.suspend!
      execution.post(system_envelope) do |e|
        latch.count_down
      end
      expect(latch.wait(0.2)).to be_truthy
    end

    it "does not call the second block then suspended" do
      latch1 = Concurrent::CountDownLatch.new(1)
      latch2 = Concurrent::CountDownLatch.new(1)

      execution.post(envelope) do |e|
        latch1.count_down
        execution.suspend!
      end

      execution.post(envelope) do |e|
        latch2.count_down
      end

      expect(latch1.wait(0.1)).to be_truthy
      expect(latch2.wait(0.1)).to be_falsey

      execution.resume!

      expect(latch2.wait(0.2)).to be_truthy
    end

    it "rejects the block while shutting down" do
      latch = Concurrent::CountDownLatch.new(1)
      execution.post(envelope) { sleep(1) }
      execution.shutdown
      begin
        execution.post(envelope) { latch.count_down }
      rescue Concurrent::RejectedExecutionError
      end
      expect(latch.wait(0.1)).to be_falsey
    end

    it "rejects the block once shutdown" do
      execution.shutdown
      latch = Concurrent::CountDownLatch.new(1)
      begin
        execution.post(envelope) { latch.count_down }
      rescue Concurrent::RejectedExecutionError
      end
      expect(latch.wait(0.1)).to be_falsey
    end
  end

  context "auto terminate" do
    # https://github.com/ruby-concurrency/concurrent-ruby/issues/817
    # https://github.com/ruby-concurrency/concurrent-ruby/issues/839
    it "does not stop shutdown " do
      Timeout.timeout(10) do
        test_file = File.join File.dirname(__FILE__), "executor_quits.rb"
        pid = spawn RbConfig.ruby, test_file
        Process.waitpid pid
        expect($?.success?).to eq true
      rescue Errno::ECHILD
        # child already gone
      rescue Timeout::Error => e
        Process.kill :KILL, pid
        raise e
      end
    end
  end

  context "#running?" do
    it "returns true when the thread pool is running" do
      expect(execution).to be_running
    end

    it "returns false when the thread pool is shutting down" do
      execution.post(envelope) { sleep(0.5) }
      execution.shutdown
      expect(execution).not_to be_running
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
    end

    it "returns false when the thread pool is shutdown" do
      execution.shutdown
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
      expect(subject).not_to be_running
    end

    it "returns false when the thread pool is killed" do
      execution.kill
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
      expect(subject).not_to be_running
    end
  end

  context "#shuttingdown?" do
    it "returns false when the thread pool is running" do
      expect(subject).not_to be_shuttingdown
    end

    it "returns false when the thread pool is shutdown" do
      execution.shutdown
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
      expect(subject).not_to be_shuttingdown
    end
  end

  context "#shutdown?" do
    it "returns false when the thread pool is running" do
      expect(subject).not_to be_shutdown
    end

    it "returns true when the thread pool is shutdown" do
      execution.shutdown
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
      expect(subject).to be_shutdown
    end
  end

  context "#shutdown" do
    it "stops accepting new tasks" do
      latch1 = Concurrent::CountDownLatch.new(1)
      latch2 = Concurrent::CountDownLatch.new(1)
      execution.post(envelope) {
        sleep(0.1)
        latch1.count_down
      }
      latch1.wait(1)
      execution.shutdown
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
      begin
        execution.post(envelope) { latch2.count_down }
      rescue Concurrent::RejectedExecutionError
      end
      expect(latch2.wait(0.2)).to be_falsey
    end

    it "allows in-progress tasks to complete" do
      latch = Concurrent::CountDownLatch.new(1)
      execution.post(envelope) {
        sleep(0.1)
        latch.count_down
      }
      execution.shutdown
      expect(latch.wait(1)).to be_truthy
    end

    it "allows pending tasks to complete" do
      latch = Concurrent::CountDownLatch.new(2)
      execution.post(envelope) {
        sleep(0.2)
        latch.count_down
      }
      execution.post(envelope) {
        sleep(0.2)
        latch.count_down
      }
      execution.shutdown
      expect(latch.wait(1)).to be_truthy
    end
  end

  context "#shutdown followed by #wait_for_termination" do
    it "allows in-progress tasks to complete" do
      latch = Concurrent::CountDownLatch.new(1)
      execution.post(envelope) {
        sleep(0.1)
        latch.count_down
      }
      execution.shutdown
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
      expect(latch.wait(1)).to be_truthy
    end

    it "allows pending tasks to complete" do
      q = Queue.new
      5.times do |i|
        execution.post(envelope) {
          sleep 0.1
          q << i
        }
      end
      execution.shutdown
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
      expect(q.length).to eq 5
    end

    it "stops accepting/running new tasks" do
      expected = Concurrent::AtomicFixnum.new(0)
      execution.post(envelope) {
        sleep(0.1)
        expected.increment
      }
      execution.post(envelope) {
        sleep(0.1)
        expected.increment
      }
      execution.shutdown
      begin
        execution.post(envelope) { expected.increment }
      rescue Concurrent::RejectedExecutionError
      end
      expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
      expect(expected.value).to eq(2)
    end
  end

  context "#kill" do
    it "stops accepting new tasks" do
      expected = Concurrent::AtomicBoolean.new(false)
      latch = Concurrent::CountDownLatch.new(1)
      execution.post(envelope) {
        sleep(0.1)
        latch.count_down
      }
      latch.wait(1)
      execution.kill
      begin
        execution.post(envelope) { expected.make_true }
      rescue Concurrent::RejectedExecutionError
      end
      sleep(0.1)
      expect(expected.value).to be_falsey
    end

    it "rejects all pending tasks" do
      execution.post(envelope) { sleep(1) }
      sleep(0.1)
      execution.kill
      sleep(0.1)
      begin
        expect(execution.post(envelope) { nil }).to be_falsey
      rescue Concurrent::RejectedExecutionError
      end
    end
  end

  context "#wait_for_termination" do
    it "immediately returns true when no operations are pending" do
      execution.shutdown
      expect(execution.wait_for_termination(0)).to be_truthy
    end

    it "returns true after shutdown has complete" do
      10.times { subject.post(envelope) {} }
      sleep(0.1)
      execution.shutdown
      expect(execution.wait_for_termination(pool_termination_timeout)).to be_truthy
    end

    it "returns true when shutdown successfully completes before timeout" do
      execution.post(envelope) { sleep(0.5) }
      sleep(0.1)
      execution.shutdown
      expect(execution.wait_for_termination(pool_termination_timeout)).to be_truthy
    end

    it "returns false when shutdown fails to complete before timeout" do
      unless execution.serialized?
        latch = Concurrent::CountDownLatch.new 1
        100.times { execution.post(envelope) { latch.wait } }
        sleep(0.1)
        execution.shutdown
        expect(execution.wait_for_termination(0.01)).to be_falsey
        latch.count_down
      end
    end

    it "waits forever when no timeout value is given" do
      execution.post(envelope) { sleep(0.5) }
      sleep(0.1)
      execution.shutdown
      expect(execution.wait_for_termination).to be_truthy
    end
  end
end
