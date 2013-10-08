/*******************************************************************************
 *
 * class UI.Image
 *
 ******************************************************************************/


Image.prototype = new Control();
Image.prototype.constructor = Image;

function Image( jquery_element ) {
  Control.call( this, jquery_element );
}

UI.Image = Image;

Image.add = function( properties ) {
  // Build DOM objects.
  var $control = $('<img/>');
  $control.addClass('control control-image');
  // Initialize wrapper.
  var control = new Image( $control );
  control.update( properties );
  // Attach to document.
  control.attach();
  return control;
}

Image.prototype.set_file = function( value ) {
  this.control.attr( 'src', value );
  return value;
};
