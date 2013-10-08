module SKUI

  require File.join( PATH, 'control.rb' )


  # @since 1.0.0
  class Checkbox < Control

    # @return [String]
    # @since 1.0.0
    prop( :label, &TypeCheck::STRING )

    # @return [Boolean]
    # @since 1.0.0
    prop_reader_bool( :checked, &TypeCheck::BOOLEAN )

    # @since 1.0.0
    define_event( :change )
    define_event( :click )
    
    # @param [String] label
    # @param [Boolean] checked
    #
    # @since 1.0.0
    def initialize( label, checked = false )
      super()
      @properties[ :label ]   = label
      @properties[ :checked ] = checked
    end

    # @return [Boolean]
    # @since 1.0.0
    def check!
      checked = true
    end

    # @return [Boolean]
    # @since 1.0.0
    def checked?
      checked = window.bridge.get_checkbox_state( ui_id )
    end

    # @return [Boolean]
    # @since 1.0.0
    def toggle!
      checked = !checked?
    end
    
    # @return [Boolean]
    # @since 1.0.0
    def uncheck!
      checked = false
    end

  end # class
end # module