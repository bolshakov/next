# frozen_string_literal: true

module Next
  DeadLetter = Data.define(:sender, :recipient, :message)
end
