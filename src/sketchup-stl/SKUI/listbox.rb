module SKUI

  require File.join( PATH, 'control.rb' )


  # @since 1.0.0
  class Listbox < Control

    # @return [Array<String>]
    # @since 1.0.0
    prop_reader( :items )
    
    # @return [Boolean]
    # @since 1.0.0
    prop_bool( :multiple, &TypeCheck::BOOLEAN )

    # @return [Integer]
    # @since 1.0.0
    prop( :size, &TypeCheck::INTEGER )

    # @since 1.0.0
    define_event( :change )
    
    # @param [Array<String>] list
    # @param [Proc] on_click
    #
    # @since 1.0.0
    def initialize( list = [] )
      unless list.is_a?( Array )
        raise( ArgumentError, 'Not an array.' )
      end
      # (?) Check for String content? Convert to strings? Accept #to_a objects?
      super()
       # (?) Should the :items list be a Hash instead? To allow key/value pairs.
      @properties[ :items ] = list
      @properties[ :multiple ] = false
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
      else
        index = arg
      end
      if index < 0 || index >= @properties[ :items ].length
        raise( ArgumentError, 'Index out of range.' )
      end
      @properties[ :items ].delete_at( index )
      window.bridge.call( 'UI.Listbox.remove_item', ui_id, index )
      nil
    end

    # @return [String]
    # @since 1.0.0
    def value
      data = window.bridge.get_value( "##{ui_id} select" )
      @properties[ :value ] = data
      data
    end
    
    # @param [String] string
    #
    # @return [String]
    # @since 1.0.0
    def value=( string )
      unless @properties[ :items ].include?( string )
        raise( ArgumentError, "'#{string}' not a valid value in list." )
      end
      @properties[ :value ] = string
      update_properties( :value )
      string
    end

  end # class
end # module