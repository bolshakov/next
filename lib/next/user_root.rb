# frozen_string_literal: true

module Next
  # Root is the parent of all the actors defined by a user.
  class UserRoot < Actor
    CreateActor = Data.define(:props, :name, :promise)

    def receive(message)
      case message
      in CreateActor(props:, name:, promise:)
        create_actor(props:, name:, promise:)
      end
    end

    private def create_actor(props:, name:, promise:)
      child = context.actor_of(props, name)
      promise.success!(child)
    rescue => error
      promise.failure!(error)
    end
  end
end
