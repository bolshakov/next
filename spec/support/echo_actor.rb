# frozen_string_literal: true

class EchoActor < Next::Actor
  def self.props = Next.props(self)

  def receive(message)
    sender << message
  end
end
