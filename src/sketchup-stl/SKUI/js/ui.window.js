/*******************************************************************************
 *
 * class UI.Window
 *
 ******************************************************************************/


Window.prototype = new Base();
Window.prototype.constructor = Window;

function Window( jquery_element ) {
  Control.call( this, jquery_element );
  this.cancel_button = null;
  this.default_button = null;
  this.control.data( 'control_class', this.typename );
}

UI.Window = Window;

Window.init = function( properties ) {
  // Capture Return and ESC for default button actions.
  $(document).on('keydown', function( event ) {
    switch ( event.keyCode ) {
    case UI.KEYCODE_ENTER:
      // Don't trigger if multiline textbox is active.
      if ( $(document.activeElement).prop('nodeName') != 'TEXTAREA' ) {
        $(Window.default_button).trigger('click');
        event.preventDefault();
        event.stopPropagation();
        return false;
      }
      break;
    case UI.KEYCODE_ESC:
      $(Window.cancel_button).trigger('click');
      event.preventDefault();
      event.stopPropagation();
      return false;
      break;
    }
  });
  // Catch when the window received and looses focus.
  // (i) These events doesn't trigger correctly when Firebug Lite is active
  //     because it introduces frames that interfere with the focus
  //     notifications.
  $(window).on( 'focus', function( event ) {
    control = UI.get_control( 'body' );
    control.callback( 'focus' );
  });
  $(window).on( 'blur', function( event ) {
    control = UI.get_control( 'body' );
    control.callback( 'blur' );
  });
  $(window).resize( function( event ) {
    var width = $( window ).width();
    var height = $( window ).height();
    control = UI.get_control( 'body' );
    control.callback( 'resize', [width, height] );
  });
  return;
}

Window.add = function( properties ) {
  return $('body');
}

Window.prototype.set_cancel_button = function( value ) {
  Window.cancel_button = '#'+value;
  return value;
};

Window.prototype.set_default_button = function( value ) {
  Window.default_button = '#'+value;
  return value;
};

Window.prototype.set_theme = function( value ) {
  // Remove any existing active theme.
  $active_theme = $('#SKUI_CSS_THEME');
  if ( $active_theme.length ) {
    $active_theme.prop( 'disabled', true );
    $active_theme.remove();
  }
  // Apply new theme.
  if ( value ) {
    $theme = $('<link>');
    $theme.attr( 'id', 'SKUI_CSS_THEME' );
    $theme.attr( 'rel', 'stylesheet' );
    $theme.attr( 'type', 'text/css' );
    $theme.attr( 'media', 'screen' );
    $theme.attr( 'href', value );
    $('#SKUI_CSS_CORE').after( $theme );
  }
  return value;
};
