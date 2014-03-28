# @since 1.0.0
module SKUI

  # Method to load SKUI into a given namespace - ensuring SKUI can be
  # distributed easily within other projects.
  #
  # @example
  #   module Example
  #     load File.join( skui_path, 'SKUI', 'embed_skui.rb' )
  #     ::SKUI.embed_in( self )
  #     # SKUI module is now available under Example::SKUI
  #   end
  #
  # @param [Module] context
  #
  # @return [Boolean]
  # @since 1.0.0
  def self.embed_in( context )
    # Temporarily rename existing root SKUI.
    Object.send( :const_set, :SKUI_Temp, SKUI )
    Object.send( :remove_const, :SKUI )
    # Load SKUI for this SKUI implementation.
    path = File.dirname( __FILE__ )
    # In SU2014, with Ruby 2.0 the __FILE__ constant return an UTF-8 string with
    # incorrect encoding label which will cause load errors when the file path
    # contain multi-byte characters. This happens when the user has non-english
    # characters in their username.
    path.force_encoding( "UTF-8" ) if path.respond_to?( :force_encoding )
    core = File.join( path, 'core.rb' )
    loaded = require( core )
    # One can only embed SKUI into one context per SKUI installation. This is
    # because `require` prevents the files to be loaded multiple times.
    # This should not be an issue though as an extension that implements SKUI
    # should only use the SKUI version it distribute itself.
    if loaded
      # Move SKUI to the target context.
      context.send( :const_set, :SKUI, SKUI )
      Object.send( :remove_const, :SKUI )
      true
    else
      false
    end
  ensure
    # Restore root SKUI and clean up temp namespace.
    Object.send( :const_set, :SKUI, SKUI_Temp )
    Object.send( :remove_const, :SKUI_Temp )
  end

end # module