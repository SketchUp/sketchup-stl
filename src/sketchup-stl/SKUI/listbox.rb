module SKUI

  require File.join( PATH, 'control.rb' )


  # @since 1.0.0
  class Listbox < Control

    # @return [Array<String>]
    # @since 1.0.0
    prop_reader( :items )

    # @return [Boolean]
    # @since 1.0.0
    prop_reader_bool( :multiple, &TypeCheck::BOOLEAN )

    # @return [Integer]
    # @since 1.0.0
    prop( :size, &TypeCheck::INTEGER )

    # @since 1.0.0
    define_event( :change )

    # @param [Array<String>] list
    #
    # @since 1.0.0
    def initialize( list = [] )
      unless list.is_a?( Array )
        raise( ArgumentError, 'Not an array.' )
      end
      # (?) Check for String content? Convert to strings? Accept #to_a objects?
      super()
       # (?) Should the :items list be a Hash instead? To allow key/value pairs.
      @properties[ :items ] = list.dup
      @properties[ :multiple ] = false # Select multiple.
      @properties[ :size ] = 1 # Makes no sense!
    end

    # @overload add_item(string, ...)
    #   @param [String] string
    #
    # @overload add_item(array)
    #   @param [Array<String>] array
    #
    # @return [Integer]
    # @since 1.0.0

    def add_item( *args )
      args = args[0] if args.size == 1 && args[0].is_a?( Array )
      @properties[ :items ].concat( args )
      for string in args
        window.bridge.call( 'UI.Listbox.add_item', ui_id, string )
      end
      args.length
    end

    # @return [Nil]
    # @since 1.0.0
    def clear
      @properties[ :items ].clear
      window.bridge.call( 'UI.Listbox.clear', ui_id )
      nil
    end

    # @overload insert(index, string, ...)
    #   @param [String] string
    #
    # @return [Integer]
    # @since 1.0.0
    def insert( index, *args )
      unless index.is_a?(Integer)
        raise( ArgumentError, 'Index must be an integer.' )
      end
      for string in args.reverse
        @properties[ :items ].insert( index, string )
        window.bridge.call( 'UI.Listbox.add_item', ui_id, string, index )
      end
      args.length
    end

    # @return [Boolean]
    # @since 1.0.0
    def move_selected_up
      return false if items.empty?
      cache_value = self.value
      return false unless cache_value
      index = items.index( cache_value )
      return false if index == 0
      new_index = index - 1
      remove_item( index )
      insert( new_index, cache_value )
      self.value = cache_value
      true
    end

    # @return [Boolean]
    # @since 1.0.0
    def move_selected_down
      return false if items.empty?
      cache_value = self.value
      return false unless cache_value
      index = items.index( cache_value )
      return false if index >= items.length - 1
      new_index = index + 2
      insert( new_index, cache_value )
      remove_item( index )
      self.value = cache_value
      true
    end

    # @param [Boolean] value
    #
    # @return [Boolean]
    # @since 1.0.0
    def multiple=( value )
      value = TypeCheck::BOOLEAN.call( value )
      if value && self.size < 2
        raise( ArgumentError,
          'Can only select multiple when size is greater than 1.' )
      end
      @properties[ :multiple ] = value
      update_properties( :multiple )
      value
    end

    # @overload remove_item(string)
    #   @param [String] string
    #
    # @overload remove_item(index)
    #   @param [Integer] index
    #
    # @return [Nil]
    # @since 1.0.0
    def remove_item( arg )
      if arg.is_a?( String )
        index = @properties[ :items ].index( arg )
        unless index
          raise( ArgumentError, 'Invalid item.' )
        end
      elsif arg.is_a?( Integer )
        index = arg
      else
        raise( ArgumentError, 'Invalid argument.' )
      end
      if index < 0 || index >= @properties[ :items ].length
        raise( ArgumentError, 'Index out of range.' )
      end
      @properties[ :items ].delete_at( index )
      window.bridge.call( 'UI.Listbox.remove_item', ui_id, index )
      nil
    end

    # @param [Integer] value
    #
    # @return [Integer]
    # @since 1.0.0
    def size=( value )
      value = TypeCheck::INTEGER.call( value )
      if value < 2
        @properties[ :size ] = value
        @properties[ :multiple ] = false
        update_properties( :size, :multiple )
      else
        @properties[ :size ] = value
        update_properties( :size )
      end
      value
    end

    # @return [String]
    # @since 1.0.0
    def value
      data = window.bridge.get_value( "##{ui_id} select" )
      @properties[ :value ] = data
      data
    end

    # @overload value=(string)
    #   @param [String] string
    #   @return [String]
    #
    # @overload value=(string,...)
    #   @param [String] string
    #   @return [Array<String>]
    #
    # @overload value=(strings)
    #   @param [Array<String>] strings
    #   @return [Array<String>]
    # @since 1.0.0
    def value=( *args )
      if args.size == 1 && args[0].is_a?( Array )
        #return self.value=( *args[0] )
        return send( :value=, *args[0] )
      end

      unless args.all? { |item| item.is_a?( String ) }
        raise( ArgumentError, 'Arguments must be strings.' )
      end

      if !self.multiple? && args.size > 1
        raise( ArgumentError, 'Not configured to select multiple items.' )
      end

      items = @properties[ :items ]
      unless (items | args).length == items.length
        not_in_list = (args - items).join(', ')
        raise( ArgumentError, "'#{not_in_list}' not valid values in list." )
      end

      @properties[ :value ] = args.dup
      update_properties( :value )
      args
    end

  end # class
end # module
