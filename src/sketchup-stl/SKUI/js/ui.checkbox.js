/*******************************************************************************
 *
 * class UI.Checkbox
 *
 ******************************************************************************/


Checkbox.prototype = new Control();
Checkbox.prototype.constructor = Checkbox;

function Checkbox( jquery_element ) {
  Control.call( this, jquery_element );
}

UI.Checkbox = Checkbox;

Checkbox.add = function( properties ) {
  // Build DOM objects.
  var $control = $('<label/>');
  $control.addClass('control control-checkbox');
  var $label = $('<span/>');
  var $checkbox = $('<input type="checkbox" />');
  $checkbox.appendTo( $control );
  $label.appendTo( $control );
  // Initialize wrapper.
  var control = new Checkbox( $control );
  control.update( properties );
  // Set up events.
  UI.add_event( 'change', $control, $checkbox );
  // Attach to document.
  control.attach();
  return control;
}

Checkbox.prototype.set_checked = function( value ) {
  $checkbox = this.control.children('input');
  $checkbox.prop( 'checked', value );
  return value;
};

Checkbox.prototype.set_label = function( value ) {
  $label = this.control.children('span');
  $label.text( value );
  return value;
};

Checkbox.prototype.set_tab_index = function( value ) {
  $checkbox = this.control.children('input');
  $checkbox.attr( 'tabIndex', value );
  return value;
};
