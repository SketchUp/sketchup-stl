module SKUI

  require File.join( PATH, 'enum.rb' )


  # @since 1.0.0
  module SystemColor

    extend Enum

    # @see http://webdesign.about.com/od/colorcharts/l/blsystemcolors.htm

    ACTIVE_BORDER        = 'ActiveBorder'.freeze
    ACTIVE_CAPTION       = 'ActiveCaption'.freeze
    APP_WORKSPACE        = 'AppWorkspace'.freeze
    BACKGROUND           = 'Background'.freeze
    BUTTON_FACE          = 'ButtonFace'.freeze
    BUTTON_HIGHLIGHT     = 'ButtonHighlight'.freeze
    BUTTON_SHADOW        = 'ButtonShadow'.freeze
    BUTTON_TEXT          = 'ButtonText'.freeze
    CAPTION_TEXT         = 'CaptionText'.freeze
    DISABLED_TEXT        = 'GrayText'.freeze
    HIGHLIGHT            = 'Highlight'.freeze
    HIGHLIGHT_TEXT       = 'HighlightText'.freeze
    INACTIVE_BORDER      = 'InactiveBorder'.freeze
    INACTIVE_CAPTION     = 'InactiveCaption'.freeze
    INACTIVE_CAPTIONTEXT = 'InactiveCaptionText'.freeze
    MENU                 = 'Menu'.freeze
    MENU_TEXT            = 'MenuText'.freeze
    SCROLLBAR            = 'Scrollbar'.freeze
    THREED_DARK_SHADOW   = 'ThreeDDarkShadow'.freeze
    THREED_FACE          = 'ThreeDFace'.freeze
    THREED_HIGHLIGHT     = 'ThreeDHighlight'.freeze
    THREED_LIGHT_SHADOW  = 'ThreeDLightShadow'.freeze
    THREED_SHADOW        = 'ThreeDShadow'.freeze
    TOOLTIP_BACKGROUND   = 'InfoBackground'.freeze
    TOOLTIP_TEXT         = 'InfoText'.freeze
    WINDOW               = 'Window'.freeze
    WINDOW_FRAME         = 'WindowFrame'.freeze
    WINDOW_TEXT          = 'WindowText'.freeze

  end # module
end # module