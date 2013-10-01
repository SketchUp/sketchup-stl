/*******************************************************************************
 *
 * class UI.Textbox
 *
 ******************************************************************************/


Textbox.prototype = new Control();
Textbox.prototype.constructor = Textbox;

function Textbox( jquery_element ) {
  Control.call( this, jquery_element );
}

UI.Textbox = Textbox;

Textbox.add = function( properties ) {
  // Build DOM objects.
  // (i) <SELECT> element needs to be wrapped to ensure consistent sizing.
  var $control = $('<div/>');
  $control.addClass('control control-textbox');
  if ( properties.multiline ) {
    var $textbox = $('<textarea/>');
  } else {
    var $textbox = $('<input type="text" />');
  }
  $textbox.attr('id', properties.ui_id + '_ui');
  $textbox.addClass('focus-target');
  $textbox.appendTo( $control );
  // Initialize wrapper.
  var control = new Textbox( $control );
  control.update( properties );
  // Set up events.
  UI.add_event( 'change', $control, $textbox );
  UI.add_event( 'keydown', $control, $textbox );
  UI.add_event( 'keypress', $control, $textbox );
  UI.add_event( 'keyup', $control, $textbox );
  UI.add_event( 'focus', $control, $textbox );
  UI.add_event( 'blur', $control, $textbox );
  UI.add_event( 'copy', $control, $textbox );
  UI.add_event( 'cut', $control, $textbox );
  UI.add_event( 'paste', $control, $textbox );
  UI.add_event( 'textchange', $control, $textbox );
  // Attach to document.
  control.attach();
  return control;
}

Textbox.prototype.set_value = function( value ) {
  $textbox = this.control.children('input,textarea');
  $textbox.val( value );
  return value;
};
