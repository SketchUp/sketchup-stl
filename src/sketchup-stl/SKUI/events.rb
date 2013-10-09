module SKUI

  require File.join( PATH, 'debug.rb' )


  # @since 1.0.0
  module Events

    # In order to create an class instance variable for each control type that
    # holds a list of the valid events for the control this 
    #
    # Adapted from:
    # http://www.railstips.org/blog/archives/2006/11/18/class-and-instance-variables-in-ruby/
    # http://www.railstips.org/blog/archives/2009/05/15/include-vs-extend-in-ruby/
    #
    # @param [Module] including_module
    #
    # @since 1.0.0
    def self.included( including_module )
      # Hash table of valid events for the class.
      # >   Key: (Symbol)
      # > Value: (Symbol)
      including_module.instance_variable_set( :@control_events, {} )
      including_module.extend( EventDefinitions )
    end

    # @since 1.0.0
    def initialize
      super()
      # Hash with Symbols for keys idenitfying the event.
      # Each event is an array of Proc's.
      @events = {}
    end
    
    # Adds an event handler to the stack. Each event can have multiple handlers.
    #
    # @param [Symbol] event
    # @param [Proc] block
    #
    # @return [nil]
    # @since 1.0.0
    def add_event_handler( event, &block )
      unless self.class.has_event?( event )
        raise( ArgumentError, "Event #{event} not defined for #{self.class}" )
      end
      unless block_given?
        raise( ArgumentError, 'No block given.' )
      end
      @events[event] ||= []
      @events[event] << block
      nil
    end
    alias :on :add_event_handler

    # Detaches all event handlers. Useful when one want to allow the objects to
    # be garbage collected.
    #
    # @return [nil]
    # @since 1.0.0
    def release_events
      @events.clear
      nil
    end
    
    # Triggers the given event. All attached procs for the given event will be
    # called. If any event handler raises an error the remaining handlers will
    # not be executed.
    #
    # @param [Symbol] event
    # @param [Array] args Set of arguments to be passed to the called procs.
    #
    # @return [Boolean]
    # @since 1.0.0
    def trigger_event( event, *args )
      #Debug.puts( "#{self.class}.trigger_event(#{event.to_s})" )
      #Debug.puts( args.inspect )
      if @events.key?( event )
        @events[event].each { |proc|
          # Add self to argument list so the called event can get the handle for
          # the control triggering it.
          if args.empty?
            proc.call( self )
          else
            args.unshift( self )
            proc.call( *args )
          end
        }
        true
      else
        false
      end
    end

    # The methods defined here becomes 'static' class methods.
    #
    # @since 1.0.0
    module EventDefinitions
      
      # When a new class inherits the class that include Events we want to make
      # sure that the event definitions of the superclass is cascaded into the
      # subclass. This is done here by copying the event defintions.
      #
      # @param [Class] subclass
      #
      # @since 1.0.0
      def inherited( subclass )
        parent_events = instance_variable_get( :@control_events ).dup
        subclass.instance_variable_set( :@control_events, parent_events )
      end

      # Defines an event for the control. If an event is not defined it cannot
      # be called.
      #
      # @overload set( event, ... )
      #   @param [Symbol] event
      #
      # @return [Nil]
      # @since 1.0.0
      def define_event( *args )
        for event in args
          unless event.is_a?( Symbol )
            raise( ArgumentError, 'Expected a Symbol' )
          end
          @control_events[event] = event
        end
        nil
      end

      # Returns an array of availible events.
      #
      # @return [Array<Symbol>]
      # @since 1.0.0
      def events
        @control_events.keys
      end
      
      # @return [Array<Symbol>]
      # @since 1.0.0
      def has_event?( event )
        @control_events.key?( event )
      end
      
    end # module EventDefinitions

  end # module Events
end # module