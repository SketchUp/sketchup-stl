module SKUI

  require File.join( PATH, 'control.rb' )


  # @since 1.0.0
  class Groupbox < Container

    # @return [String]
    # @since 1.0.0
    prop( :label, &TypeCheck::STRING )

    # @param [String] label
    #
    # @since 1.0.0
    def initialize( label = '' )
      super()
      @properties[ :label ] = label
    end

  end # class
end # module