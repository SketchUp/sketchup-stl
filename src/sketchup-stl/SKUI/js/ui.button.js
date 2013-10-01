/*******************************************************************************
 *
 * class UI.Button
 *
 ******************************************************************************/


Button.prototype = new Control();
Button.prototype.constructor = Button;

function Button( jquery_element ) {
  Control.call( this, jquery_element );
}

UI.Button = Button;

Button.add = function( properties ) {
  // Build DOM objects.
  var $control = $('<button></button>');
  $control.addClass('control control-button');
  // Initialize wrapper.
  var control = new Button( $control );
  control.update( properties );
  // Set up events.
  UI.add_event( 'click', $control );
  // Attach to document.
  control.attach();
  return control;
}

Button.init = function( properties ) {
  // (?) Needed? What IE version is this a hack for?
  $(document).on('mousedown', 'button', function() {
    $(this).addClass('pressed');
    return false;
  });
  $(document).on('mouseup', 'button', function() {
    $(this).removeClass('pressed');
    return false;
  });
  return;
}

Button.prototype.set_caption = function( value ) {
  this.control.text( value );
  return value;
};
