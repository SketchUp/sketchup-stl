/*******************************************************************************
 *
 * class UI.Label
 *
 ******************************************************************************/


Label.prototype = new Control();
Label.prototype.constructor = Label;

function Label( jquery_element ) {
  Control.call( this, jquery_element );
}

UI.Label = Label;

Label.add = function( properties ) {
  // Build DOM objects.
  var $control = $('<label><a/></label>');
  $control.addClass('control control-label');
  // Initialize wrapper.
  var control = new Label( $control );
  control.update( properties );
  // Attach to document.
  control.attach();
  return control;
}

Label.prototype.set_align = function( value ) {
  // `value` is a Symbol in Ruby and becomes a string like ":left" in JS.
  var css_value = value.substring( 1, value.length );
  this.control.css('text-align', css_value);
  return value;
};

Label.prototype.set_caption = function( value ) {
  $a = this.control.children('a');
  $a.text( value );
  return value;
};

Label.prototype.set_control = function( value ) {
  var control_id = value
  var $control = $( '#'+value );
  // Some times the actual UI element (INPUT, TEXTAREA, etc) might be wrapped in
  // another HTML element. An assumption is made that the actual UI element is
  // an immediate child of the wrapper and has a ".focus-target" class.
  var $focus_target = $control.children('.focus-target');
  if ( $focus_target.length > 0 ) {
    control_id = $focus_target.attr('id');
  }
  this.control.attr( 'for', control_id );
  return value;
};

Label.prototype.set_url = function( value ) {
  $a = this.control.children('a');
  $a.attr( 'href', value );
  return value;
};
