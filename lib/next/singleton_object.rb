# frozen_string_literal: true

module Next
  # @api private
  class SingletonObject
    attr_reader :name
    private :name

    def initialize(name)
      @name = name.to_s
    end

    def inspect
      "#<#{name}>"
    end
    alias_method :to_s, :inspect
    alias_method :to_str, :inspect
  end

  private_constant(:SingletonObject)
end
