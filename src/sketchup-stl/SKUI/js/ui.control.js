/*******************************************************************************
 *
 * class UI.Control
 *
 ******************************************************************************/


Control.prototype = new Base();
Control.prototype.constructor = Control;

function Control( jquery_element ) {
  Base.call( this, jquery_element );
}

Control.prototype.set_disabled = function( value ) {
  this.control.toggleClass( 'disabled', value );
  this.control.prop( 'disabled', value );
  this.control.prop( 'readonly', value );
  // Disable form controls.
  // (!) Bug when enabling a parent control when a child is set to disabled.
  $form_elements = this.control.find( 'input, select, textarea, button' );
  $form_elements.prop( 'readonly', value );
  return value;
};

Control.prototype.set_enabled = function( value ) {
  this.set_disabled( !value );
  return value;
};

Control.prototype.set_visible = function( value ) {
  if ( value ) {
    this.control.css( 'visibility', 'visible' );
  } else {
    this.control.css( 'visibility', 'hidden' );
  }
  return value;
};

Control.prototype.set_top = function( value ) {
  this.control.css( 'top', value );
  return value;
};

Control.prototype.set_left = function( value ) {
  this.control.css( 'left', value );
  return value;
};

Control.prototype.set_bottom = function( value ) {
  this.control.css( 'bottom', value );
  return value;
};

Control.prototype.set_right = function( value ) {
  this.control.css( 'right', value );
  return value;
};

Control.prototype.set_width = function( value ) {
  this.control.outerWidth( value );
  return value;
};

Control.prototype.set_height = function( value ) {
  this.control.outerHeight( value );
  return value;
};

Control.prototype.set_z_index = function( value ) {
  this.control.css( 'z-index', value );
  return value;
};

Control.prototype.set_tab_index = function( value ) {
  this.control.attr( 'tabIndex', value );
  return value;
};

Control.prototype.set_tooltip = function( value ) {
  this.control.prop( 'title', value );
  return value;
};
