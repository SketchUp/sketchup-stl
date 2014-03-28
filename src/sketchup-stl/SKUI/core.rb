# @since 1.0.0
module SKUI

  # In SU2014, with Ruby 2.0 the __FILE__ constant return an UTF-8 string with
  # incorrect encoding label which will cause load errors when the file path
  # contain multi-byte characters. This happens when the user has non-english
  # characters in their username.
  current_path = File.dirname( __FILE__ )
  if current_path.respond_to?( :force_encoding )
    current_path.force_encoding( "UTF-8" )
  end

  # @since 1.0.0
  PATH      = current_path.freeze
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