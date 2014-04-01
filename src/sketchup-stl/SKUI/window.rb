module SKUI

  require File.join( PATH, 'base.rb' )
  require File.join( PATH, 'bridge.rb' )
  require File.join( PATH, 'control_manager.rb' )
  require File.join( PATH, 'debug.rb' )


  # Basic window class. Use this as the foundation for custom window types.
  #
  # @since 1.0.0
  class Window < Base

    include ControlManager

    # @return [String]
    # @since 1.0.0
    prop( :cancel_button, &TypeCheck::BUTTON )

    # @return [String]
    # @since 1.0.0
    prop( :default_button, &TypeCheck::BUTTON )

    # @return [String]
    # @since 1.0.0
    prop( :theme, &TypeCheck::STRING )

    # @since 1.0.0
    define_event( :ready )

    # @since 1.0.0
    define_event( :close )

    # @since 1.0.0
    define_event( :focus, :blur )

    # @since 1.0.0
    define_event( :resize )

    # @since 1.0.0
    define_event( :scripts_loaded )

    # @since 1.0.0
    THEME_DEFAULT  = nil
    THEME_GRAPHITE = File.join( PATH_CSS, 'theme_graphite.css' ).freeze

    # @private
    attr_reader( :bridge )

    # @param [Hash] options
    #
    # @since 1.0.0
    def initialize( options = {} )
      super()

      defaults = {
        :title            => 'Untitled',

        :left             => 400,
        :top              => 250,
        :width            => 300,
        :height           => 200,

        :width_limit      => nil,
        :height_limit     => nil,

        :resizable        => false,
        :minimize         => false,
        :maximize         => false,

        :modal            => false,

        :preferences_key  => nil,

        :theme            => THEME_DEFAULT
      }
      active_options = defaults.merge( options )

      @options = active_options

      @properties[:theme] = @options[:theme]

      @scripts = []
      @loaded_scripts = []

      # Create a dummy WebDialog here in order for the Bridge to respond in a
      # more sensible manner other than being `nil`. The WebDialog is recreated
      # right before the window is displayed due to a SketchUp bug.
      # @see #show
      @webdialog = UI::WebDialog.new
      @bridge = Bridge.new( self, @webdialog )
    end

    # Adds the given JavaScript. This allow custom solutions outside of SKUI's
    # Ruby class wrappers.
    #
    # @return [Nil]
    # @since 1.0.0
    def add_script(script_file)
      unless File.exist?(script_file)
        raise ArgumentError, "File not found: #{script_file}"
      end
      @scripts << script_file
      nil
    end

    # Returns an array with the width and height of the client area.
    #
    # @return [Array(Integer,Integer)]
    # @since 1.0.0
    def client_size
      @bridge.call( 'WebDialog.get_client_size' )
    end

    # Adjusts the window so the client area fits the given +width+ and +height+.
    #
    # @param [Array(Integer,Integer)] value
    #
    # @return [Boolean] Returns false if the size can't be set.
    # @since 2.5.0
    def client_size=( value )
      width, height = value
      unless @webdialog.visible?
        # (?) Queue up size for when dialog opens.
        return false
      end
      # (!) Cache size difference.
      @webdialog.set_size( width, height )
      client_width, client_height = client_size()
      adjust_width  = width  - client_width
      adjust_height = height - client_height
      unless adjust_width == 0 && adjust_height == 0
        new_width  = width  + adjust_width
        new_height = height + adjust_height
        @webdialog.set_size( new_width, new_height )
      end
      true
    end

    # @return [Nil]
    # @since 1.0.0
    def bring_to_front
      @webdialog.bring_to_front
    end

    # @return [Nil]
    # @since 1.0.0
    def close
      @webdialog.close
    end

    # @see Base#release
    # @return [Nil]
    # @since 1.0.0
    def release
      @webdialog.close if @webdialog.visible?
      super
      @bridge.release
      @bridge = nil
      @options.clear
      @options = nil
      @webdialog = nil
      nil
    end

    # @overload set_position( left, top )
    #   @param [Numeric] left
    #   @param [Numeric] top
    #
    # @return [Nil]
    # @since 1.0.0
    def set_position( *args )
      @webdialog.set_position( *args )
    end

    # @overload set_size( width, height )
    #   @param [Numeric] width
    #   @param [Numeric] height
    #
    # @return [Nil]
    # @since 1.0.0
    def set_size( *args )
      @webdialog.set_size( *args )
    end

    # @since 1.0.0
    def show
      if @webdialog.visible?
        @webdialog.bring_to_front
      else
        # Recreate WebDialog instance in order for last position and size to be
        # used. Otherwise old preferences would be used.
        @webdialog = init_webdialog( @options )
        @bridge.webdialog = @webdialog
        # OSX doesn't have modal WebDialogs. Instead a 'modal' WebDialog means
        # it'll stay on top of the SketchUp window - where as otherwist it'd
        # fall behind.
        if PLATFORM_IS_OSX
          # (!) Implement alternative for OSX modal windows.
          @webdialog.show_modal
        else
          if @options[:modal]
            @webdialog.show_modal
          else
            @webdialog.show
          end
        end
      end
    end

    # @return [String]
    # @since 1.0.0
    def title
      @options[:title].dup
    end

    # @return [Nil]
    # @since 1.0.0
    def toggle
      if visible?
        close()
      else
        show()
      end
    end

    # @return [Boolean]
    # @since 1.0.0
    def visible?
      @webdialog.visible?
    end

    # @overload write_image( image_path, top_left_x, top_left_y,
    #                        bottom_right_x, bottom_right_y )
    #   @param [String] image_path
    #   @param [Numeric] top_left_x
    #   @param [Numeric] top_left_y
    #   @param [Numeric] bottom_right_x
    #   @param [Numeric] bottom_right_y
    #
    # @return [Nil]
    # @since 1.0.0
    def write_image( *args )
      @webdialog.write_image( *args )
    end

    # @private
    #
    # Because closures captures the local variables, including `self` the
    # callback is set up in a class method to prevent the closure from capturing
    # the reference to the `Window` instance. It's not pretty, but it ensures
    # that all objects can be garbage collected.
    #
    # @param [UI::WebDialog] webdialog
    # @param [String] callback_name
    # @param [Symbol] method_id
    #
    # @return [Nil]
    # @since 1.0.0
    def self.add_callback( webdialog, callback_name, method_id )
      webdialog.add_action_callback( callback_name ) { |wd, params|
        window = nil
        ObjectSpace.each_object( Bridge ) { |bridge|
          if bridge.webdialog == wd
            window = bridge.window
            break
          end
        }
        window.send( method_id, wd, params )
      }
      # Cleans up the capture references from the block. Otherwise the webdialog
      # will not be garbage collected.
      webdialog = nil
      nil
    end

    private

    # @param [UI::WebDialog] webdialog
    # @param [String] callback_name
    # @param [Symbol] method_id
    #
    # @return [Nil]
    # @since 1.0.0
    def add_callback( webdialog, callback_name, method_id )
      # Syntax sugar wrapping the original implementation.
      self.class.add_callback( webdialog, callback_name, method_id )
      nil
    end

    # Called when a control triggers an event.
    # params possibilities:
    #   "<callback>||<*arguments>"
    #
    # @param [UI::WebDialog] webdialog
    # @param [String] params
    #
    # @return [Nil]
    # @since 1.0.0
    def callback_handler( webdialog, params )
      #Debug.puts( '>> Callback' )
      #Debug.puts( params )
      callback, *arguments = params.split('||')
      #Debug.puts( callback )
      #Debug.puts( arguments )
      case callback
      when 'SKUI::Console.log'
        Debug.puts( *arguments )
      when 'SKUI::Control.on_event'
        ui_id, event, *event_arguments = arguments
        event_control_callback( ui_id, event.intern, *event_arguments )
      when 'SKUI::Window.on_open_url'
        event_open_url( arguments[0] )
      when 'SKUI::Window.on_ready'
        event_window_ready( webdialog )
      when 'SKUI::Window.on_script_loaded'
        event_script_loaded( arguments[0] )
      end
    ensure
      # Inform the Webdialog the message was received so it can process any
      # remaining messages.
      @bridge.call( 'Bridge.pump_message' )
      nil
    end

    # Called when the HTML DOM is ready.
    #
    # @param [UI::WebDialog] webdialog
    #
    # @return [Nil]
    # @since 1.0.0
    def event_window_ready( webdialog )
      Debug.puts( '>> Dialog Ready' )
      @bridge.call( 'Bridge.set_window_id', ui_id )
      unless @scripts.empty?
        @loaded_scripts.clear
        @bridge.call( 'WebDialog.add_scripts', @scripts )
      end
      update_properties( *@properties.keys )
      @bridge.add_container( self )
      trigger_event( :ready )
      nil
    end

    # @param [String] ui_id
    # @param [Symbol] event
    #
    # @return [Nil]
    # @since 1.0.0
    def event_control_callback( ui_id, event, *arguments )
      #Debug.puts( '>> Event Callback' )
      #Debug.puts( "   > ui_id: #{ui_id}" )
      #Debug.puts( "   > Event: #{event}" )
      # Process Control
      control = find_control_by_ui_id( ui_id )
      if control
        control.trigger_event( event, *arguments )
      end
    end

    # Called when a URL link is clicked.
    #
    # @param [String] url
    #
    # @return [Nil]
    # @since 1.0.0
    def event_open_url( url )
      Debug.puts( '>> Open URL' )
      UI.openURL( url )
      nil
    end


    # @param [String] script
    #
    # @return [Nil]
    # @since 1.0.0
    def event_script_loaded( script )
      #Debug.puts( "SKUI::Window.event_script_loaded(#{script})" )
      @loaded_scripts << script
      if @loaded_scripts.sort == @scripts.sort
        trigger_event( :scripts_loaded )
      end
      nil
    end

    # @○param [Hash] options Same as #initialize
    #
    # @return [UI::WebDialog]
    # @since 1.0.0
    def init_webdialog( options )
      # Convert options to Webdialog arguments.
      wd_options = {
        :dialog_title     => options[:title],
        :preferences_key  => options[:preferences_key],
        :resizable        => options[:resizable],
        :scrollable       => false,
        :left             => options[:left],
        :top              => options[:top],
        :width            => options[:width],
        :height           => options[:height]
      }
      webdialog = UI::WebDialog.new( wd_options )
      # (?) Not sure if it's needed, but setting this to true for the time being.
      if webdialog.respond_to?( :set_full_security= )
        webdialog.set_full_security = true
      end
      # Hide the navigation buttons that appear on OSX.
      if webdialog.respond_to?( :navigation_buttons_enabled= )
        webdialog.navigation_buttons_enabled = false
      end
      # Ensure the size for fixed windows is set - otherwise SketchUp will use
      # the last saved properties.
      unless options[:resizable]
        # OSX has a bug where it ignores the resize flag and let the user resize
        # the window. Setting the min and max values for width and height works
        # around this issue.
        #
        # To make things worse, OSX sets the client size with the min/max
        # methods - causing the window to grow if you set the min size to the
        # desired target size. To account for this we set the min sizes to be
        # a little less that the desired width. The size should be larger than
        # the titlebar height.
        #
        # All this has to be done before we set the size in order to restore the
        # desired size because the min/max methods will transpose the external
        # size to content size.
        #
        # The result is that the height is adjustable a little bit, but at least
        # it's restrained to be close to the desired size. Lesser evil until
        # this is fixed in SketchUp.
        webdialog.min_width = options[:width]
        webdialog.max_width = options[:width]
        webdialog.min_height = options[:height] - 30
        webdialog.max_height = options[:height]

        webdialog.set_size( options[:width], options[:height] )
      end
      # Limit the size of the window. The limits can be either an Integer for
      # the maximum size of the window or a Range element which defines both
      # minimum and maximum size. If `range.max` return `nil` then there is no
      # maximum size.
      if options[:width_limit]
        if options[:width_limit].is_a?( Range )
          minimum = [ 0, options[:width_limit].min ].max
          maximum = options[:width_limit].max
          webdialog.min_width = minimum
          webdialog.max_width = maximum if maximum
        else
          webdialog.max_width = options[:width_limit]
        end
      end
      if options[:height_limit]
        if options[:height_limit].is_a?( Range )
          minimum = [ 0, options[:height_limit].min ].max
          maximum = options[:height_limit].max
          webdialog.min_width = minimum
          webdialog.max_width = maximum if maximum
        else
          webdialog.max_width = options[:height_limit]
        end
      end
      # (i) If procs are created for #add_action_callback in instance methods
      #     then the WebDialog instance will not GC. Call a wrapper that
      #     prevents this.
      add_callback( webdialog, 'SKUI_Callback', :callback_handler )
      # Hook up events to capture when the window closes.
      webdialog.set_on_close {
        trigger_event( :close )
      }
      # (i) There appear to be differences between OS when the HTML content
      #     is prepared. OSX loads HTML on #set_file? Inspect this.
      html_file = File.join( PATH_HTML, 'window.html' )
      webdialog.set_file( html_file )
      webdialog
    end

  end # class
end # module
