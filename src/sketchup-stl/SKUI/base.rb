module SKUI
  # @since 1.0.0
  class Base

    require File.join( PATH, 'enum_system_color.rb' )
    require File.join( PATH, 'enum_system_font.rb' )
    require File.join( PATH, 'events.rb' )
    require File.join( PATH, 'font.rb' )
    require File.join( PATH, 'json.rb' )
    require File.join( PATH, 'properties.rb' )
    require File.join( PATH, 'typecheck.rb' )

    include Events
    extend Properties

    # ID string used by both Ruby and the WebDialog to keep each control in
    # sync with each other when passing properties and events.
    #
    # @return [String]
    # @since 1.0.0
    prop_reader( :ui_id ) # (i) :id would conflict with Object.id

    # @return [ControlManager, Nil]
    # @since 1.0.0
    prop( :parent, &TypeCheck::CONTAINER )

    # @return [Font, SystemFont]
    # @since 1.0.0
    prop( :font, &TypeCheck::FONT )

    # @return [Sketchup::Color, SystemColor]
    # @since 1.0.0
    prop( :foreground_color, &TypeCheck::COLOR )

    # @return [Sketchup::Color, SystemColor]
    # @since 1.0.0
    prop( :background_color, &TypeCheck::COLOR )

    # @return [JSON]
    # @since 1.0.0
    attr_accessor( :properties )

    # @return [Window, Nil]
    # @since 1.0.0
    attr_accessor( :window )

    # @since 1.0.0
    def initialize
      super()
      # @properties contains all the data that must be shared with the webdialog
      # in order to sync everything on both ends.
      @properties = JSON.new
      @properties[ :ui_id ] = "UI_#{object_id()}"
      @properties[ :type ] = typename()
    end

    # @return [String]
    # @since 1.0.0
    def inspect
      "<#{self.class}:#{object_id_hex}>"
    end

    # @return [String]
    # @since 1.0.0
    def to_js
      ui_id.inspect
    end

    # Release all references to other objects. Setting them to nil. So that
    # the GC can collect them.
    #
    # @return [Nil]
    # @since 1.0.0
    def release
      release_events()
      @properties.clear
      @properties = nil
      @parent = nil
      nil
    end

    # @return [String]
    # @since 1.0.0
    def typename
      self.class.to_s.split( '::' ).last
    end

    # @return [Window|Nil]
    # @since 1.0.0
    def window
      control = self
      until control.parent.nil?
        control = control.parent
      end
      # Unless the root element is a Window then the control hasn't been added
      # to the window yet.
      ( control.is_a?( Window ) ) ? control : nil
    end

    private

    # @return [String]
    # @since 1.0.0
    def object_id_hex
      "0x%x" % ( object_id << 1 )
    end

    private

    # Call this method whenever a control property changes, spesifying which
    # properties changed. This is sent to the WebDialog for syncing.
    #
    # @param [Symbol] properties
    #
    # @return [Boolean]
    # @since 1.0.0
    def update_properties( *properties )
      if window && window.visible?
        # These properties must always be included unmodified.
        base_properties = {
          :type => typename()
        }
        # The given properties will be sent to the WebDialog where it updates
        # the UI to match the state of the Ruby objects.
        control_properties = JSON.new
        for property in properties
          control_properties[ property ] = @properties[ property ]
        end
        control_properties.merge!( base_properties )
        window.bridge.call( 'UI.update_properties', ui_id, control_properties )
        true
      else
        false
      end
    end

  end # class
end # module
