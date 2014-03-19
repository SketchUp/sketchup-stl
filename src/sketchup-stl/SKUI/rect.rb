module SKUI
  # Returns the position and size of the control as reported by the WebDialog.
  # The WebDialog must be ready and visible for these methods to work.
  #
  # @since 1.0.0
  class Rect

    # @param [Control] control
    #
    # @since 1.0.0
    def initialize( control )
      unless control.is_a?( Control )
        raise( ArgumentError, 'Not a valid control.' )
      end
      @control = control
    end

    # @return [Integer]
    # @since 1.0.0
    def left
      get_rect[ 'left' ]
    end

    # @return [Integer]
    # @since 1.0.0
    def top
      get_rect[ 'top' ]
    end

    # @return [Integer]
    # @since 1.0.0
    def right
      get_rect[ 'right' ]
    end

    # @return [Integer]
    # @since 1.0.0
    def bottom
      get_rect[ 'bottom' ]
    end

    # @return [Integer]
    # @since 1.0.0
    def width
      get_rect[ 'width' ]
    end

    # @return [Integer]
    # @since 1.0.0
    def height
      get_rect[ 'height' ]
    end

    # @see Base#release
    # @return [Nil]
    # @since 1.0.0
    def release
      @control = nil
      nil
    end

    # @return [Hash]
    # @since 1.0.0
    def to_hash
      hash = get_rect
      keys = hash.keys.map { |string| string.intern }
      Hash[ *keys.zip(hash.values).flatten ]
    end

    private

    # @return [Hash]
    # @since 1.0.0
    def get_rect
      id = @control.ui_id
      @control.window.bridge.get_control_rect( id )
    end

  end # class
end # module
