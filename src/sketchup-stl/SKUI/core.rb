# @since 1.0.0
module SKUI

  # @since 1.0.0
  PATH      = File.dirname( __FILE__ ).freeze
  PATH_JS   = File.join( PATH, 'js' ).freeze
  PATH_CSS  = File.join( PATH, 'css' ).freeze
  PATH_HTML = File.join( PATH, 'html' ).freeze

  # @since 1.0.0
  PLATFORM_IS_OSX     = ( Object::RUBY_PLATFORM =~ /darwin/i ) ? true : false
  PLATFORM_IS_WINDOWS = !PLATFORM_IS_OSX

  # Version and release information.
  require File.join( PATH, 'version.rb' )

  # Configure Debug mode.
  require File.join( PATH, 'debug.rb' )
  Debug.enabled = false


  # Load the availible UI control classes.
  require File.join( PATH, 'button.rb' )
  require File.join( PATH, 'checkbox.rb' )
  require File.join( PATH, 'container.rb' )
  require File.join( PATH, 'groupbox.rb' )
  require File.join( PATH, 'image.rb' )
  require File.join( PATH, 'label.rb' )
  require File.join( PATH, 'listbox.rb' )
  require File.join( PATH, 'radiobutton.rb' )
  require File.join( PATH, 'textbox.rb' )
  require File.join( PATH, 'window.rb' )


  # @return [Integer] Number of files reloaded.
  # @since 1.0.0
  def self.reload
    original_verbose = $VERBOSE
    $VERBOSE = nil
    filter = File.join( PATH, '*.{rb,rbs}' )
    x = Dir.glob( filter ).each { |file|
      load file
    }
    x.length
  ensure
    $VERBOSE = original_verbose
  end

end # module
