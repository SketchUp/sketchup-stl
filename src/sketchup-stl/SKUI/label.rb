module SKUI

  require File.join( PATH, 'control.rb' )


  # @since 1.0.0
  class Label < Control

    # @return [Control]
    # @since 1.0.0
    prop( :align, &TypeCheck::TEXTALIGN )

    # @return [String]
    # @since 1.0.0
    prop( :caption, &TypeCheck::STRING )

    # @return [Control]
    # @since 1.0.0
    prop( :control, &TypeCheck::CONTROL )

    # @return [String]
    # @since 1.0.0
    prop( :url, &TypeCheck::STRING )

    # @since 1.0.0
    define_event( :open_url )
    
    # @param [String] caption
    # @param [Control] control Control which focus of forwarded to.
    #
    # @since 1.0.0
    def initialize( caption, control = nil )
      super()

      @properties[ :align ]   = :left
      @properties[ :caption ] = caption
      @properties[ :control ] = control

      add_event_handler( :open_url ) { |param|
        UI.openURL( param )
      }
    end

  end # class
end # module