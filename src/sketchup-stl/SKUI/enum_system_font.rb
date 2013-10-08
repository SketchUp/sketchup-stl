module SKUI

  require File.join( PATH, 'enum.rb' )


  # @since 1.0.0
  module SystemFont

    extend Enum

    # @see http://www.w3.org/TR/CSS2/fonts.html#font-shorthand

    # The font used for captioned controls (e.g., buttons, drop-downs, etc.).
    CAPTION       = 'caption'.freeze

    # The font used to label icons.
    ICON          = 'icon'.freeze

    # The font used in menus (e.g., dropdown menus and menu lists).
    MENU          = 'menu'.freeze

    # The font used in dialog boxes.
    MESSAGEBOX    = 'message-box'.freeze

    # The font used for labeling small controls.
    SMALL_CAPTION = 'small-caption'.freeze

    # The font used in window status bars.
    STATUSBAR     = 'status-bar'.freeze

  end # module
end # module