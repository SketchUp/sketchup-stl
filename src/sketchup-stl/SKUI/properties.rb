module SKUI
  # Mix-in module for the Control class. Simplifies the definition of properties
  # with getter and setter methods that access the +@properties+ stack.
  #
  # @since 1.0.0
  module Properties

    private

    # @param [Symbol] symbols
    #
    # @return [Nil]
    # @since 1.0.0
    def prop( *symbols, &block )
      prop_reader( *symbols )
      prop_writer( *symbols, &block )
      nil
    end
    alias :prop_accessor :prop

    # @param [Symbol] symbols
    #
    # @return [Nil]
    # @since 1.0.0
    def prop_bool( *symbols )
      prop_reader_bool( *symbols )
      prop_writer( *symbols )
      nil
    end

    # @param [Symbol] symbols
    #
    # @return [Nil]
    # @since 1.0.0
    def prop_reader( *symbols )
      self.class_eval {
        # (i) Must use `#each` instead of `for in` because otherwise the symbol
        #     variable would not be locale to each method definition and
        #     @properties[ symbol ] would point to the last `symbol` in the
        #     `symbols` array.
        symbols.each { |symbol|
          define_method( symbol ) {
            @properties[ symbol ]
          }
        }
      }
      nil
    end

    # @param [Symbol] symbols
    #
    # @return [Nil]
    # @since 1.0.0
    def prop_reader_bool( *symbols )
      self.class_eval {
        symbols.each { |symbol|
          symbol_bool = "#{symbol}?".intern
          define_method( symbol_bool ) {
            @properties[ symbol ]
          }
        }
      }
      nil
    end

    # If a block is given it will be evaluated before the property is set. The
    # block is given one argument, the new value of the property. Use this to
    # add argument validation to the property.
    #
    # @param [Symbol] symbols
    #
    # @return [Nil]
    # @since 1.0.0
    def prop_writer( *symbols, &block )
      self.class_eval {
        symbols.each { |symbol|
          symbol_set = "#{symbol}=".intern
          define_method( symbol_set ) { |value|
            value = block.call( value ) if block
            @properties[ symbol ] = value
            update_properties( symbol )
            value
          }
        }
      }
      nil
    end

  end # module
end # module