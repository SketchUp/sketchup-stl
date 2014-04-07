module SKUI

  require File.join( PATH, 'base.rb' )
  require File.join( PATH, 'rect.rb' )


  # Base class which all SKUI controls inherit from.
  #
  # @since 1.0.0
  class Control < Base

    # Alternative way to refer to a Control - by assigning a Symbol name to it
    # you can refer to a control like so: `window.find_control_by_name( :foo )`
    #
    # @return [Symbol]
    # @since 1.0.0
    prop( :name, &TypeCheck::SYMBOL )

    # @return [Boolean]
    # @since 1.0.0
    prop_bool( :enabled, &TypeCheck::BOOLEAN )

    # @return [Boolean]
    # @since 1.0.0
    prop_bool( :visible, &TypeCheck::BOOLEAN )

    # @return [Integer]
    # @since 1.0.0
    prop( :left, :top, :right, :bottom, &TypeCheck::INTEGER )

    # @return [Integer]
    # @since 1.0.0
    prop( :width, :height, &TypeCheck::INTEGER )

    # @return [Integer]
    # @since 1.0.0
    prop( :z_index, &TypeCheck::INTEGER )

    # @return [Integer]
    # @since 1.0.0
    prop( :tab_index, &TypeCheck::INTEGER )

    # @return [String]
    # @since 1.0.0
    prop( :tooltip, &TypeCheck::STRING )

    # @since 1.0.0
    prop_writer( :font_name, :font_size ) # (!) Needs more work.

    # @return [Rect]
    # @since 1.0.0
    attr_reader( :rect )

    # @since 1.0.0
    def initialize
      super()
      @rect = Rect.new( self )
    end

    # Positive `x` value will anchor the control to the left side of the
    # container, negative will anchor the control to the right side.
    #
    # Likewise for y, positive anchors to the top, negative anchors to the
    # bottom.
    #
    # Not that if you have previously set `left` and `right`to stretch the
    # control within it's parent the stretch will be reset.
    #
    # @param [Numeric] x
    # @param [Numeric] y
    #
    # @return [Array(x,y)]
    # @since 1.0.0
    def position( x, y )
      if x < 0
        @properties[ :right ] = x.abs
        @properties[ :left ] = nil
      else
        @properties[ :left ] = x
        @properties[ :right ] = nil
      end
      if y < 0
        @properties[ :bottom ] = y.abs
        @properties[ :top ] = nil
      else
        @properties[ :top ] = y
        @properties[ :bottom ] = nil
      end
      update_properties( :left, :top, :right, :bottom )
      [ x, y ]
    end

    # @see Base#release
    # @return [Nil]
    # @since 1.0.0
    def release
      super
      @rect.release
      @rect = nil
      nil
    end

    # @param [Numeric] width
    # @param [Numeric] height
    #
    # @return [Array(width,height)]
    # @since 1.0.0
    def size( width, height )
      @properties[ :width ]  = width
      @properties[ :height ] = height
      update_properties( :width, :height )
      [ width, height ]
    end

    # @param [Numeric] left
    # @param [Numeric] top
    # @param [Numeric] right
    # @param [Numeric] bottom
    #
    # @return [Array(left,top,right,bottom)]
    # @since 1.0.0
    def stretch( left, top, right, bottom )
      @properties[ :left ]   = left
      @properties[ :top ]    = top
      @properties[ :right ]  = right
      @properties[ :bottom ] = bottom
      update_properties( :left, :top, :right, :bottom )
      [ left, top, right, bottom ]
    end

  end # class
end # module
