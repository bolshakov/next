# frozen_string_literal: true

class ActorWithInspector < Next::Actor
  def self.props(inspector: Next::LocalStorage.current_identity) = Next.props(self, inspector:)

  attr_reader :inspector

  def initialize(inspector:)
    @inspector = inspector
  end

  def receive(message)
    puts "mssag"
    inspector << message
  end
end
