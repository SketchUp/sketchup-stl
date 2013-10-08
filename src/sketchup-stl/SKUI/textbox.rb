module SKUI

  require File.join( PATH, 'control.rb' )


  # @since 1.0.0
  class Textbox < Control

    # @return [String]
    # @since 1.0.0
    prop_writer( :value, &TypeCheck::STRING )

    # @return [Boolean]
    # @since 1.0.0
    prop_bool( :multiline, &TypeCheck::BOOLEAN )

    # @since 1.0.0
    define_event( :change )
    define_event( :textchange )
    define_event( :keydown, :keypress, :keyup )
    define_event( :focus, :blur )
    define_event( :copy, :cut, :paste )
    
    # @param [String] value
    #
    # @since 1.0.0
    def initialize( value = '' )
      super()
      @properties[ :value ] = value
    end

    # @return [String]
    # @since 1.0.0
    def value
      data = window.bridge.get_value( "##{ui_id} input, ##{ui_id} textarea" )
      @properties[ :value ] = data
      data
    end

  end # class
end # module