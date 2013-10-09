module SKUI
  # Sortable Hash that preserves the insertion order.
  # When converted to strings it output a JavaScript JSON string that can be
  # used in WebDialogs for instance.
  #
  # Based of Bill Kelly's InsertOrderPreservingHash
  #
  # @see http://www.ruby-forum.com/topic/166075#728764
  #
  # @since 1.0.0
  class JSON

    include Enumerable

    # @since 1.0.0
    def initialize( *args, &block )
      if args.size == 1 && args[0].is_a?( Hash )
        @hash = args[0].dup
        @ordered_keys = @hash.keys
      else
        @hash = Hash.new( *args, &block )
        @ordered_keys = []
      end
    end
    
    # @since 1.0.0
    def initialize_copy( source )  
      super  
      @hash = @hash.dup
      @ordered_keys = @ordered_keys.dup  
    end  

    # @since 1.0.0
    def []=( key, value )
      @ordered_keys << key unless @hash.has_key?( key )
      @hash[key] = value
    end

    # @since 1.0.0
    def clear
      @hash.clear
      @ordered_keys.clear
    end

    # @since 1.0.0
    def each
      @ordered_keys.each { |key| yield( key, @hash[key] ) }
    end
    alias :each_pair :each

    # @since 1.0.0
    def each_value
      @ordered_keys.each { |key| yield( @hash[key] ) }
    end

    # @since 1.0.0
    def each_key
      @ordered_keys.each { |key| yield key }
    end
    
    # @since 1.0.0
    def key?( key )
      @hash.key?( key )
    end
    alias :has_key? :key?
    alias :include? :key?
    alias :member? :key?
    
    # @since 1.0.0
    def keys
      @ordered_keys
    end
    
    # @since 1.0.0
    def values
      @ordered_keys.map { |key| @hash[key] }
    end

    # @since 1.0.0
    def clear
      @ordered_keys.clear
      @hash.clear
    end

    # @since 1.0.0
    def delete( key, &block )
      @ordered_keys.delete( key )
      @hash.delete( key, &block )
    end

    # @since 1.0.0
    def reject!
      del = []
      each_pair { |key, value| del << key if yield( key, value ) }
      del.each { |key| delete( key ) }
      del.empty? ? nil : self
    end

    # @since 1.0.0
    def delete_if( &block )
      reject!( &block )
      self
    end

    # @since 1.0.0
    def merge!( hash )
      hash.each { |key, value|
        if @hash.key?( key )
          @hash[key] = value
        else
          self[key] = value
        end
      }
    end

    # @since 1.0.0
    def method_missing( *args )
      @hash.send( *args )
    end
    
    # @return [Hash]
    # @since 1.0.0
    def to_hash
      @hash.dup
    end
    
    # Compile JSON Hash into a string.
    #
    # @param [Boolean] format Set to true for pretty print.
    #
    # @return [String]
    # @since 1.0.0
    def to_s( format = false )
      data = self.map { |key, value|
        json_key = ( key.is_a?(Symbol) ) ? key.to_s.inspect : key.inspect
        json_value = self.class.object_to_js( value, format )
        "#{json_key}: #{json_value}"
      }
      json_string = (format) ? data.join(",\n\t") : data.join(", ")
      return (format) ? "{\n\t#{json_string}\n}\n" : "{#{json_string}}"
    end
    alias :inspect :to_s

    # Converts given Ruby object to a JavaScript string.
    #
    # @param [Object] object
    # @param [Boolean] format Set to true for pretty print.
    #
    # @return [String]
    # @since 1.0.0
    def self.object_to_js( object, format = false )
      if object.is_a?( self )
        object.to_s( format )
      elsif object.is_a?( Hash )
        self.new( object ).to_s( format )
      elsif object.is_a?( Symbol )
        object.inspect.inspect
      elsif object.is_a?( Regexp )
        o = object.options
        i = o & Regexp::EXTENDED == Regexp::EXTENDED ? 'i' : '' # Invalid in JS
        i = o & Regexp::IGNORECASE == Regexp::IGNORECASE ? 'i' : ''
        m = o & Regexp::MULTILINE == Regexp::MULTILINE ? 'm' : ''
        "/#{object.source}/#{i}#{m}"
      elsif object.nil?
        'null'
      elsif object.is_a?( Array )
        data = object.map { |obj| object_to_js( obj, format ) }
        "[#{data.join(',')}]"
      elsif object.is_a?( Geom::Point3d )
        "new Point3d( #{object.to_a.join(', ')} )"
      elsif object.is_a?( Geom::Vector3d )
        "new Vector3d( #{object.to_a.join(', ')} )"
      elsif object.is_a?( Sketchup::Color )
        "new Color( #{object.to_a.join(', ')} )"
      elsif object.respond_to?( :to_js )
        object.to_js
      else
        # String, Integer, Float, TrueClass, FalseClass.
        # (!) Filter out accepted objects.
        # (!) Convert unknown into strings - then inspect.
        object.inspect
      end
    end
  
  end # class
end # module