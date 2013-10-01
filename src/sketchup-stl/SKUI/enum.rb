module SKUI
  # @since 1.0.0
  module Enum

    def valid?( value )
      for constant in  self.constants
        return true if self.const_get( constant ) == value
      end
      return false
    end

  end # module
end # module