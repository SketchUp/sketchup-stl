module SKUI

  require File.join( PATH, 'control.rb' )


  # @since 1.0.0
  class Button < Control

    # @return [String]
    # @since 1.0.0
    prop( :caption, &TypeCheck::STRING )

    # @since 1.0.0
    define_event( :click )
    
    # @param [String] caption
    # @param [Proc] on_click
    #
    # @since 1.0.0
    def initialize( caption, &on_click )
      super()

      # Default size based on Window UX guidelines.
      #
      # http://msdn.microsoft.com/en-us/library/aa511279.aspx#controlsizing
      # http://msdn.microsoft.com/en-us/library/aa511453.aspx#sizing
      #
      # Actual:  75x23
      # Visible: 73x21
      @properties[ :width ]  = 75
      @properties[ :height ] = 23

      @properties[ :caption ] = caption

      if block_given?
        add_event_handler( :click, &on_click )
      end
    end

  end # class
end # module