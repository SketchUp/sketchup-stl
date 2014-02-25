module SKUI

  require File.join( PATH, 'control_manager.rb' )
  require File.join( PATH, 'enum_system_color.rb' )


  # Module collection of `Proc`s that can be used to check types when defining
  # properties. The Proc should return the value given. Return unmodified to
  # preserve the value as it was given, or made modifications, such as for
  # a boolean type check you want to convert the value, that might be any value,
  # to a true boolean.
  #
  # @example Make a property ensure the set value is a valid colour value.
  #   class Container < Control
  #     include ControlManager
  #     prop( :background_color, &TypeCheck::COLOR )
  #     prop( :enabled,          &TypeCheck::BOOLEAN )
  #    end
  #
  # @since 1.0.0
  module TypeCheck

    # @since 1.0.0
    BOOLEAN = Proc.new { |value|
      # Cast the value into true boolean values.
      value ? true : false
    }

    # @since 1.0.0
    BUTTON = Proc.new { |value|
      unless value.is_a?( Button )
        raise( ArgumentError, 'Not a valid button.' )
      end
      value
    }

    # @since 1.0.0
    COLOR = Proc.new { |value|
      unless value.is_a?( Sketchup::Color ) || SystemColor.valid?( value )
        raise( ArgumentError, 'Not a valid color.' )
      end
      value
    }

    # @since 1.0.0
    CONTAINER = Proc.new { |value|
      unless value.is_a?( ControlManager )
        raise( ArgumentError, 'Not a valid container control.' )
      end
      value
    }

    # @since 1.0.0
    CONTROL = Proc.new { |value|
      unless value.is_a?( Control )
        raise( ArgumentError, 'Not a valid control.' )
      end
      value
    }

    # @since 1.0.0
    FONT = Proc.new { |value|
      unless value.is_a?( Font ) || SystemFont.valid?( value )
        raise( ArgumentError, 'Not a valid font.' )
      end
      value
    }

    # @since 1.0.0
    INTEGER = Proc.new { |value|
      unless value.respond_to?( :to_i )
        raise( ArgumentError, 'Not a valid Integer value.' )
      end
      value.to_i
    }

    # @since 1.0.0
    TEXTALIGN = Proc.new { |value|
      unless [:left, :center, :right].include?( value )
        raise( ArgumentError, 'Not a valid alignment value.' )
      end
      value
    }

    # @since 1.0.0
    STRING = Proc.new { |value|
      unless value.respond_to?( :to_s )
        raise( ArgumentError, 'Not a valid String value.' )
      end
      value.to_s
    }

    # @since 1.0.0
    SYMBOL = Proc.new { |value|
      unless value.is_a?( Symbol )
        raise( ArgumentError, 'Not a Symbol.' )
      end
      value
    }

  end # module
end # module
