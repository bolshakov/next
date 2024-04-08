# frozen_string_literal: true

RSpec.describe Next::SerializedPriorityExecution do
  subject(:execution) { Next::SerializedPriorityExecutionDelegator.new(executor) }

  let(:executor) { Concurrent::ImmediateExecutor.new }
  let(:pool_termination_timeout) { 10 }

  after(:each) do
    execution.shutdown
    expect(execution.wait_for_termination(pool_termination_timeout)).to eq true
  end

  context "#post" do
    it "calls the block with the given arguments" do
      latch = Concurrent::CountDownLatch.new(1)
      expected = nil
      execution.post(1, 2, 3) do |a, b, c|
        expected = [a, b, c]
        latch.count_down
      end
      latch.wait(0.2)
      expect(expected).to eq [1, 2, 3]
    end
  end
end
