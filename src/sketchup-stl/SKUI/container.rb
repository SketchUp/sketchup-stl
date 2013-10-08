module SKUI

  require File.join( PATH, 'control.rb' )
  require File.join( PATH, 'control_manager.rb' )


  # Container control grouping child controls.
  #
  # @since 1.0.0
  class Container < Control

    include ControlManager

  end # class
end # module