/*******************************************************************************
 *
 * class UI.Groupbox
 *
 ******************************************************************************/


Groupbox.prototype = new Control();
Groupbox.prototype.constructor = Groupbox;

function Groupbox( jquery_element ) {
  Control.call( this, jquery_element );
}

UI.Groupbox = Groupbox;

Groupbox.add = function( properties ) {
  // Build DOM objects.
  var $control = $('<fieldset/>');
  $control.addClass('container control control-groupbox');
  var $label = $('<legend/>');
  $label.appendTo( $control );
  // Initialize wrapper.
  var control = new Groupbox( $control );
  control.update( properties );
  // Attach to document.
  control.attach();
  return control;
}

Groupbox.prototype.set_label = function( value ) {
  $label = this.control.children('legend');
  $label.text( value );
  return value;
};
