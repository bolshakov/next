# frozen_string_literal: true

RSpec.describe Next::SerializedExecution::Stash do
  subject(:stash) { described_class.new(suspended:) }
  let(:task) { -> {} }
  let(:suspended) { false }

  def job(message)
    Next::SerializedExecution::Job.new(
      executor: nil,
      envelope: Next::Envelope.new(message:, sender: nil),
      block: task
    )
  end

  def system_job(message)
    job(message.extend(Next::SystemMessage))
  end

  it "is empty initially" do
    is_expected.to be_empty
  end

  it "can add an element to the end" do
    stash.push(job(42))

    expect(stash.to_a).to eq([job(42)])
    expect(stash).not_to be_empty
    expect(stash.shift).to be_some_of(job(42))
    expect(stash).to be_empty
  end

  it "can add multiple elements to the end" do
    stash.push(job(42), job(43), job(44))

    expect(stash.to_a).to eq([job(42), job(43), job(44)])
    expect(stash).not_to be_empty
    expect(stash.shift).to be_some_of(job(42))
    expect(stash.to_a).to eq([job(43), job(44)])
  end

  it "pushes system messages at the beginning of the stash" do
    first, second = Object.new, Object.new
    system = Object.new

    stash.push(job(first), job(second))
    stash.push(system_job(system))

    expect(stash.to_a).to eq([system_job(system), job(first), job(second)])
    expect(stash).not_to be_empty
    expect(stash.shift).to be_some_of(system_job(system))
    expect(stash.to_a).to eq([job(first), job(second)])
  end

  context "when suspended" do
    let(:suspended) { true }

    it "pushes system messages at the beginning of the stash" do
      first, second = Object.new, Object.new
      system = Object.new

      stash.push(job(first), job(second))
      stash.push(system_job(system))

      expect(stash.to_a).to eq([system_job(system), job(first), job(second)])
      expect(stash).not_to be_empty
      expect(stash.shift).to be_some_of(system_job(system))

      expect(stash.to_a).to eq([job(first), job(second)])

      expect(stash.shift).to be_none
    end
  end

  specify "#drain" do
    system_job = system_job(Object.new)

    stash.push(job(42), job(43), job(44))
    stash.push(system_job)

    expect(stash.drain).to eq([job(42), job(43), job(44)])
    expect(stash.to_a).to eq([system_job])
  end
end
