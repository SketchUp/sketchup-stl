module SKUI

  require File.join( PATH, 'control.rb' )


  # @since 1.0.0
  class Image < Control

    # @return [String]
    # @since 1.0.0
    prop( :file, &TypeCheck::STRING )
    
    # @param [String] filename
    #
    # @since 1.0.0
    def initialize( filename )
      super()
      @properties[ :file ] = filename
    end

  end # class
end # module
