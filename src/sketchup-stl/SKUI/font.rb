module SKUI
  # @since 1.0.0
  class Font

    attr_accessor( :name, :size, :bold, :italic )
    
    # @param [String] name
    # @param [Integer, Nil] size
    # @param [Boolean, Nil] bold
    # @param [Boolean, Nil] italic
    #
    # @since 1.0.0
    def initialize( name, size = nil, bold = nil, italic = nil )
      @name = name
      @size = size
      @bold = bold
      @italic = italic
    end

    # @return [String]
    # @since 1.0.0
    def to_js
      properties = JSON.new
      properties['font-family'] = @name.inspect if @name
      properties['font-size']   = "#{@size}px"  if @size
      properties['font-weight'] = 'bold'        if @bold
      properties['font-style']  = 'italic'      if @italic
      properties.to_s
    end

  end # class
end # module